//
//  HDPhoneMonitor.swift
//  HDPhoneMonitor
//
//  Created by Dinh Quang Hieu on 7/20/16.
//  Copyright © 2016 Dinh Quang Hieu. All rights reserved.
//

import UIKit
import RealmSwift

class Log: Object {
    dynamic var batteryLevel: Float = -1
    dynamic var memoryUsage: Float = -1
    dynamic var date: String = ""
    dynamic var interval: Int = -1
    override static func primaryKey() -> String? {
        return "interval"
    }
}

public class HDPhoneMonitor: NSObject {
    
    public class var sharedService: HDPhoneMonitor {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            
            static var instance: HDPhoneMonitor? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = HDPhoneMonitor()
        }
        return Static.instance!
    }
    
    public let minsPerInterval = 5
    public let userDefault = NSUserDefaults()
    
    public static func startService() {
        UIDevice.currentDevice().batteryMonitoringEnabled = true
        let _ = HDPhoneMonitor.sharedService
    }
    
    public static func deviceConnectionDidDrop() {
        sharedService.log()
    }
    
    public static func deviceDidConnect() {
        sharedService.log()
    }
    
    public static func logBatteryLevel() {
        sharedService.log()
    }
    
    public static func logMemoryUsage() {
        sharedService.log()
    }
    
    
    public func log() {
        let realm = try! Realm()
        let log = Log()
        let date = HDPhoneMonitor.getDate()
        let interval  = dayIntervalByAbsoluteMin(HDPhoneMonitor.getAbsoluteMinInDay())
        log.date = date
        log.interval = interval
        log.batteryLevel = UIDevice.currentDevice().batteryLevel * 100
        log.memoryUsage = HDPhoneMonitor.getMemoryUsage()
        
        try! realm.write {
            realm.add(log, update: true)
        }
    }
    
    public static func getDate() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        return dateFormatter.stringFromDate(NSDate())
    }
    
    public static func getAbsoluteMinInDay() -> Int {
        let midNight = "\(getDate()) 00:00:00"
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let interval = NSDate().timeIntervalSinceDate(dateFormatter.dateFromString(midNight)!)
        return Int(interval / 60) // second to minute
    }
    
    public func dayIntervalByAbsoluteMin(min: Int) -> Int {
        return min / minsPerInterval
    }
    
    public static func getMemoryUsage() -> Float {
        // constant
        let MACH_TASK_BASIC_INFO_COUNT = (sizeof(mach_task_basic_info_data_t) / sizeof(natural_t))
        
        // prepare parameters
        let name   = mach_task_self_
        let flavor = task_flavor_t(MACH_TASK_BASIC_INFO)
        var size   = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)
        
        // allocate pointer to mach_task_basic_info
        let infoPointer = UnsafeMutablePointer<mach_task_basic_info>.alloc(1)
        
        // call task_info - note extra UnsafeMutablePointer(...) call
        let kerr = task_info(name, flavor, UnsafeMutablePointer(infoPointer), &size)
        
        // get mach_task_basic_info struct out of pointer
        let info = infoPointer.move()
        
        // deallocate pointer
        infoPointer.dealloc(1)
        
        // check return value for success / failure
        if kerr == KERN_SUCCESS {
            //print("Memory in use (in MB): \(info.resident_size/1000000)")
            return Float(info.resident_size / 1000000)
        } else {
            return -1
            //let errorString = String(CString: mach_error_string(kerr), encoding: NSASCIIStringEncoding)
            //println(errorString ?? "Error: couldn't parse error string")
        }    
    }
}