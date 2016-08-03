//
//  HDPhoneMonitor.swift
//  HDPhoneMonitor
//
//  Created by Dinh Quang Hieu on 7/20/16.
//  Copyright © 2016 Dinh Quang Hieu. All rights reserved.
//

import UIKit
import RealmSwift

//MARK: - MonitoringData
class MonitoringData: Object {
    
    //MARK: - Variables
    dynamic var batteryLevel: Float = -1
    dynamic var memoryUsage: Float = -1
    dynamic var chargingStatus: Bool = false
    dynamic var date: NSDate = NSDate()
    
    //MARK: - Functions
    func interval() -> Int {
        return HDPhoneMonitor.minuteIndexInDay(date) / HDPhoneMonitor.MINUTES_PER_INTERVAL
    }
}

//MARK: - ConnectionData
class ConnectionData: Object {
    //MARK: - Variables
    dynamic var status: String = ""
    dynamic var deviceID: String = ""
    dynamic var date: NSDate = NSDate()
    
    //MARK: - Functions
    func interval() -> Int {
        return HDPhoneMonitor.minuteIndexInDay(date) / HDPhoneMonitor.MINUTES_PER_INTERVAL
    }
}

//MARK: - DataType
enum DataType: Int {
    case MonitoringData = 1, ConnectionData
}

//MARK: - HDPhoneMonitor
public class HDPhoneMonitor: NSObject {
    
    //MARK: - Monitor Variables
    
    // Replace 5 by value in [5,720] if you want change interval
    // Make sure that 5 is minimum value for best performance and 720 is the max value because 1440/720 = 2 is the minimum number of point to draw graph :)
    public static var MINUTES_PER_INTERVAL = 30
    
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
    static var isCharging = false
    static var connectionDropCount = 0
    
    //MARK: - Monitor Functions
    
    public static func startService() {
        UIDevice.currentDevice().batteryMonitoringEnabled = true
        let _ = HDPhoneMonitor.sharedService
    }
    
    public static func enableCloudStorage() {
        let _ = GoogleSheetService.sharedService
        if sharedService.userDefault.valueForKey("spreadsheetId") != nil {
            GoogleSheetService.spreadsheetId = sharedService.userDefault.valueForKey("spreadsheetId") as? String
        }
    }
    
    public func monitor() {
        
        if userDefault.valueForKey("lastTimeSaved") != nil {
            if let lastTimeSaved = userDefault.valueForKey("lastTimeSaved") as? NSDate {
                let now = NSDate()
                if Int(now.timeIntervalSinceDate(lastTimeSaved)) < 1 * 60 {
                    // Only save data every 5 mins for saving memory space
                    return
                }
            }
        }
        
        let data = MonitoringData()
        data.batteryLevel = UIDevice.currentDevice().batteryLevel * 100
        data.memoryUsage = HDPhoneMonitor.getMemoryUsage()
        
        let state = UIDevice.currentDevice().batteryState
        switch state {
        case .Charging:
            HDPhoneMonitor.isCharging = true
        case .Unplugged:
            HDPhoneMonitor.isCharging = false
        default:
            break
        }
        data.chargingStatus = HDPhoneMonitor.isCharging
        
        let realm = try! Realm()
        try! realm.write {
            realm.add(data)
            userDefault.setValue(NSDate(), forKey: "lastTimeSaved")
            userDefault.synchronize()
        }
    }
    
    public func deviceConnectionDidDrop(deviceID: String) {
        saveConnectionData(deviceID, status: "Disconnected")
    }
    
    public func deviceDidConnect(deviceID: String) {
        saveConnectionData(deviceID, status: "Connected")
    }
    
    func saveConnectionData(deviceID:String, status: String) {
        let data = ConnectionData(value: ["status": status, "deviceID": deviceID])
        let realm = try! Realm()
        try! realm.write {
            realm.add(data)
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
    
    static func canChangeMinutesPerInterval(newValue: Int) -> Bool {
        if newValue >= 5 && newValue <= 720 {
            MINUTES_PER_INTERVAL = newValue
            return true
        }
        return false
    }
}