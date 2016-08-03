//
//  GoogleSheetService.swift
//  HDPhoneMonitor
//
//  Created by Dinh Quang Hieu on 8/2/16.
//  Copyright © 2016 Dinh Quang Hieu. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleAPIClient
import GTMOAuth2

// MARK: - GoogleSheetService
class GoogleSheetService: NSObject {

    //MARK: - Google Sheet API Variables
    static let kKeychainItemName = "HDPhoneMonitor Client ID"
    static let kClientID = "558527852240-40dp6ohf8ut1qshcsp7nu09nesr7ql3h.apps.googleusercontent.com"
    static let scopes = ["https://www.googleapis.com/auth/spreadsheets"]
    static var spreadsheetId:String?
    var service:GTLService?
    let baseUrl = "https://sheets.googleapis.com/v4/spreadsheets"
    weak var delegate:GoogleSheetServiceDelegate?
    
    class var sharedService: GoogleSheetService {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            
            static var instance: GoogleSheetService? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = GoogleSheetService()
        }
        return Static.instance!
    }

    var authorizer: GTMFetcherAuthorizationProtocol! {
        didSet {
            service?.authorizer = authorizer
        }
    }
    
    
    //MARK: - Google Sheet API Functions
    
    
    override init() {
        service = GTLService()
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
        
        service!.fetchObjectByInsertingObject(object, forURL: fullUrl!, delegate: self, didFinishSelector: #selector(GoogleSheetService.displayCreatedResult(_:finishedWithObject:error:)))
    }
    
    func getValueRange(dataType:DataType) -> NSMutableDictionary {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        
        let valuerange:NSMutableDictionary = NSMutableDictionary()
        
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
        
        valuerange.setValue(values, forKey: "values")
        valuerange.setValue(dataRange, forKey: "range")
        valuerange.setValue("ROWS", forKey: "majorDimension")
        
        return valuerange
    }
    
    func sync() {
        let batchData = NSMutableDictionary()
        
        let monitoringValueRange = getValueRange(.MonitoringData)
        let connectionValueRange = getValueRange(.ConnectionData)
        
        let data = [monitoringValueRange, connectionValueRange]
        
        batchData.setValue("RAW", forKey: "valueInputOption")
        batchData.setValue(data, forKey: "data")
        
        let syncUrlString = "https://sheets.googleapis.com/v4/spreadsheets/\(GoogleSheetService.spreadsheetId!)/values:batchUpdate"
        let params = ["valueInputOption": "RAW"]
        
        let syncUrl = GTLUtilities.URLWithString(syncUrlString, queryParameters: params)
        
        let object = GTLObject(JSON: batchData)
        
        service!.fetchObjectByInsertingObject(object, forURL: syncUrl!, delegate: self, didFinishSelector: #selector(GoogleSheetService.displaySyncedResult(_:finishedWithObject:error:)))
    }
    
    func displayCreatedResult(ticket: GTLServiceTicket,
                              finishedWithObject object : GTLObject,
                                                 error : NSError?) {
        delegate?.didCreateSpreadSheet(object, error: error)
        
    }
    
    func displaySyncedResult(ticket: GTLServiceTicket,
                             finishedWithObject object : GTLObject,
                                                error : NSError?) {
        delegate?.didSync(object, error: error)
        
    }
    
}

// MARK: - Protocol
protocol GoogleSheetServiceDelegate: class {
    func didSync(object: GTLObject, error: NSError?)
    func didCreateSpreadSheet(object: GTLObject, error: NSError?)
}
