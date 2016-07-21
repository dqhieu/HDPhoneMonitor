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

class HDPhoneMonitor: NSObject {
    
    class var sharedService: HDPhoneMonitor {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            
            static var instance: HDPhoneMonitor? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = HDPhoneMonitor()
        }
        return Static.instance!
    }
    
    let minsPerInterval = 5
    let userDefault = NSUserDefaults()
    
    static func startService() {
        UIDevice.currentDevice().batteryMonitoringEnabled = true
        let _ = HDPhoneMonitor.sharedService
    }
    
    static func deviceConnectionDidDrop() {
        sharedService.log()
    }
    
    static func deviceDidConnect() {
        sharedService.log()
    }
    
    static func logBatteryLevel() {
        sharedService.log()
    }
    
    static func logMemoryUsage() {
        sharedService.log()
    }
    
    
    func log() {
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
    
    static func getDate() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        return dateFormatter.stringFromDate(NSDate())
    }
    
    static func getAbsoluteMinInDay() -> Int {
        let midNight = "\(getDate()) 00:00:00"
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let interval = NSDate().timeIntervalSinceDate(dateFormatter.dateFromString(midNight)!)
        return Int(interval / 60) // second to minute
    }
    
    func dayIntervalByAbsoluteMin(min: Int) -> Int {
        return min / minsPerInterval
    }
    
    static func getMemoryUsage() -> Float {
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