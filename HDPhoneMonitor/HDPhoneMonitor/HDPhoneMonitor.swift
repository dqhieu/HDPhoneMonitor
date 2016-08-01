//
//  HDPhoneMonitor.swift
//  HDPhoneMonitor
//
//  Created by Dinh Quang Hieu on 7/20/16.
//  Copyright © 2016 Dinh Quang Hieu. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleAPIClient
import GTMOAuth2

//MARK: - MonitoringData
class MonitoringData: Object {
    
    //MARK: - Variables
    dynamic var batteryLevel: Float = -1
    dynamic var memoryUsage: Float = -1
    dynamic var chargingStatus: Bool = false
    dynamic var date: NSDate = NSDate()
    
    //MARK: - Functions
    public func interval() -> Int {
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
    public func interval() -> Int {
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
    public static let MINUTES_PER_INTERVAL = 30
    
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
    
    //MARK: - Google Sheet API Variables
    public static var kKeychainItemName = "HDPhoneMonitor Client ID"
    public static var kClientID = "558527852240-40dp6ohf8ut1qshcsp7nu09nesr7ql3h.apps.googleusercontent.com"
    public static let scopes = ["https://www.googleapis.com/auth/spreadsheets"]
    public var googleSheetService:GTLService?
    let baseUrl = "https://sheets.googleapis.com/v4/spreadsheets"
    var spreadsheetId:String?
    var finishedTask = 0
    
    //MARK: - Monitor Functions
    
    public static func startService() {
        UIDevice.currentDevice().batteryMonitoringEnabled = true
        let _ = HDPhoneMonitor.sharedService
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
    
    //MARK: - Google Sheet API Functions
    public static func enableCloudStorage() {
        sharedService.googleSheetService = GTLService()
        if sharedService.userDefault.valueForKey("spreadsheetId") != nil {
            sharedService.spreadsheetId = sharedService.userDefault.valueForKey("spreadsheetId") as! String
        }
    }
    
    func createSpreadSheet() {
        let baseUrl = "https://sheets.googleapis.com/v4/spreadsheets"
        
        let spreadsheet:NSMutableDictionary = NSMutableDictionary()
        
        let properties:NSMutableDictionary = NSMutableDictionary()
        properties.setValue("HDPhoneMonitor Data", forKey: "title")
        
        spreadsheet.setValue(properties, forKey: "properties")
        
        var sheets = [NSMutableDictionary()]
        let sheet = NSMutableDictionary()
        let sheet2 = NSMutableDictionary()
        let sheetProperties = NSMutableDictionary()
        
        sheetProperties.setValue("MonitoringData", forKey: "title")
        sheetProperties.setValue(0, forKey: "index")
        sheet.setValue(sheetProperties, forKey: "properties")
        sheets.append(sheet)
        
        let sheetProperties2 = NSMutableDictionary()
        sheetProperties2.setValue("ConnectionData", forKey: "title")
        sheetProperties2.setValue(1, forKey: "index")
        sheet2.setValue(sheetProperties2, forKey: "properties")
        sheets.append(sheet2)
        
        spreadsheet.setValue(sheets, forKey: "sheets")
        
        let object = GTLObject(JSON: spreadsheet)
        
        let fullUrl = NSURL(string: baseUrl)
        
        googleSheetService!.fetchObjectByInsertingObject(object, forURL: fullUrl!, delegate: self, didFinishSelector: #selector(HDPhoneMonitor.displayCreateResult(_:finishedWithObject:error:)))
    }
    
    func syncData(dataType: DataType) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        
        let data:NSMutableDictionary = NSMutableDictionary()
        
        let realm = try! Realm()
        var values = [[]]
        var dataRange = ""
        //-----------------------
        switch dataType {
        case .MonitoringData:
            values = [["Date", "BatteryLevel", "Is Charging", "Memory Usage"]]
            let rdata = realm.objects(MonitoringData.self).sorted("date", ascending: true)
            for index in 0 ..< rdata.count {
                let data = rdata[index]
                let value = [String(dateFormatter.stringFromDate(data.date)), String(data.batteryLevel), String(data.chargingStatus), String(data.memoryUsage)]
                values.append(value)
            }
            dataRange = "MonitoringData!A1:D\(rdata.count + 1)"
        case .ConnectionData :
            values = [["Date", "DeviceID", "Status"]]
            let rdata = realm.objects(ConnectionData.self).sorted("date", ascending: true)
            for index in 0 ..< rdata.count {
                let data = rdata[index]
                let value = [String(dateFormatter.stringFromDate(data.date)), String(data.deviceID), String(data.status)]
                values.append(value)
            }
            dataRange = "ConnectionData!A1:D\(rdata.count + 1)"
        }
        //-----------------------
        
        data.setValue(values, forKey: "values")
        data.setValue(dataRange, forKey: "range")
        data.setValue("ROWS", forKey: "majorDimension")
        
        let params = ["valueInputOption": "RAW"]
        
        let object = GTLObject(JSON: data)
        
        let monitorDataUrl = GTLUtilities.URLWithString(String(format:"%@/%@/values/%@", baseUrl, spreadsheetId!, dataRange), queryParameters: params)
        
        
        googleSheetService!.fetchObjectByUpdatingObject(object, forURL: monitorDataUrl, delegate: self, didFinishSelector: #selector(HDPhoneMonitor.displaySyncResult(_:finishedWithObject:error:)))
    }
    
    func sync() {
        finishedTask = 0
        syncData(DataType.MonitoringData)
        syncData(DataType.ConnectionData)
    }
    
    weak var delegate:HDPhoneMonitorDelegate?
    
    func displayCreateResult(ticket: GTLServiceTicket,
                             finishedWithObject object : GTLObject,
                                                error : NSError?) {
        delegate?.didCreateSpreadSheet(object, error: error)
        
    }
    
    func displaySyncResult(ticket: GTLServiceTicket,
                                 finishedWithObject object : GTLObject,
                                                    error : NSError?) {
        if let error = error {
            delegate?.didSync(object, error: error)
            finishedTask = 0
        }
        else {
            if finishedTask < 1 {
                finishedTask += 1
                return
            }
            else {
                delegate?.didSync(object, error: error)
                finishedTask = 0
            }
        }
        
    }
    
}

protocol HDPhoneMonitorDelegate: class {
    func didSync(object: GTLObject, error: NSError?)
    func didCreateSpreadSheet(object: GTLObject, error: NSError?)
}