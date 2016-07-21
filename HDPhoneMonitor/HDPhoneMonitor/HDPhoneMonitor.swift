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
        return "date"
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
    
    let minsPerInterval = 5
    
    public static func startService() {
        UIDevice.currentDevice().batteryMonitoringEnabled = true
        let _ = HDPhoneMonitor.sharedService
    }
    
    public func log() {
        let realm = try! Realm()
        let log = Log()
        let date = HDPhoneMonitor.getDate()
        let interval  = dayIntervalByMinuteIndex(HDPhoneMonitor.minuteIndex())
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
    
    // from 0 -> 1439
    static func minuteIndex() -> Int {
        let midNight = "\(getDate()) 00:00:00"
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let interval = NSDate().timeIntervalSinceDate(dateFormatter.dateFromString(midNight)!)
        return Int(interval / 60) // second to minute
    }
    
    
    func dayIntervalByMinuteIndex(min: Int) -> Int {
        return min / minsPerInterval
    }
    
    static func getMemoryUsage() -> Float {
        let MACH_TASK_BASIC_INFO_COUNT = (sizeof(mach_task_basic_info_data_t) / sizeof(natural_t))
        
        let name   = mach_task_self_
        let flavor = task_flavor_t(MACH_TASK_BASIC_INFO)
        var size   = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)
        
        let infoPointer = UnsafeMutablePointer<mach_task_basic_info>.alloc(1)
        
        let kerr = task_info(name, flavor, UnsafeMutablePointer(infoPointer), &size)
        
        let info = infoPointer.move()
        
        infoPointer.dealloc(1)
        
        if kerr == KERN_SUCCESS {
            return Float(info.resident_size / 1000000)
        } else {
            return -1
        }
    }
}