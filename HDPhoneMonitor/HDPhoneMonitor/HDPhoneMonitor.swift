//
//  HDPhoneMonitor.swift
//  HDPhoneMonitor
//
//  Created by Dinh Quang Hieu on 7/20/16.
//  Copyright © 2016 Dinh Quang Hieu. All rights reserved.
//

import UIKit
import RealmSwift

//MARK: - Log
class MonitoringData: Object {
    
    //MARK: - Variables
    dynamic var batteryLevel: Float = -1
    dynamic var memoryUsage: Float = -1
    dynamic var date: NSDate = NSDate()
    
    //MARK: - Functions
    public func interval() -> Int {
        return HDPhoneMonitor.minuteIndexInDay(date) / HDPhoneMonitor.MINUTES_PER_INTERVAL
    }
}

//MARK: - HDPhoneMonitor
public class HDPhoneMonitor: NSObject {
    
    //MARK: - Variables
    
    // Replace 5 by value in [5,720] if you want change interval
    // Make sure that 5 is minimum value for best performance and 720 is the max value because 1440/720 = 2 is the minimum number of point to draw graph :)
    public static let MINUTES_PER_INTERVAL = 5
    
    public static let MAX_MINUTE_A_DAY = 1440
    
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
    
    let userDefault = NSUserDefaults()
    
    //MARK: - Functions
    
    public static func startService() {
        UIDevice.currentDevice().batteryMonitoringEnabled = true
        let _ = HDPhoneMonitor.sharedService
    }
    
    public func monitor() {
        
        if userDefault.valueForKey("lastTimeSaved") != nil {
            if let lastTimeSaved = userDefault.valueForKey("lastTimeSaved") as? NSDate {
                let now = NSDate()
                if Int(now.timeIntervalSinceDate(lastTimeSaved)) < 5 * 60 {
                    // Only save data every 5 mins for saving memory space
                    return
                }
            }
        }
        
        let realm = try! Realm()
        let data = MonitoringData()
        data.batteryLevel = UIDevice.currentDevice().batteryLevel * 100
        data.memoryUsage = HDPhoneMonitor.getMemoryUsage()
        
        try! realm.write {
            realm.add(data)
            userDefault.setValue(NSDate(), forKey: "lastTimeSaved")
            userDefault.synchronize()
        }
    }
    
    static func getDayString(date: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        return dateFormatter.stringFromDate(date)
    }
    
    // from 0 -> 1439
    static func minuteIndexInDay(date: NSDate) -> Int {
        let midNight = "\(getDayString(date)) 00:00:00"
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let interval = date.timeIntervalSinceDate(dateFormatter.dateFromString(midNight)!)
        return Int(interval / 60) // second to minute
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