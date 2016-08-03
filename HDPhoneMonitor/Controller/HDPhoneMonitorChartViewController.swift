//
//  HDPhoneMonitorChartViewController.swift
//  HDPhoneMonitor
//
//  Created by Dinh Quang Hieu on 7/20/16.
//  Copyright © 2016 Dinh Quang Hieu. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleAPIClient
import GTMOAuth2
import SVProgressHUD

public class HDPhoneMonitorChartViewController: UIViewController {
    
    //MARK:- Variables
    
    var lineChart:HDLineChart!
    var barChart:HDBarChart!
    var phoneData:[MonitoringData] = []
    var connectionData:[Int] = []
    var isCharging:[Bool] = []
    var cdata:Results<ConnectionData>?
    var mdata:Results<MonitoringData>?
    
    var nextButton:UIButton!
    var backButton:UIButton!
    var noDataLabel:UILabel!
    
    var day: String!
    
    var navigationBarHeight: CGFloat    = 0
    var statusBarHeight: CGFloat        = 0
    var tabBarHeight: CGFloat           = 0
    var topMargin:CGFloat               = 0
    var botMargin:CGFloat               = 0
    var chartMargin:CGFloat             = 0
    var chartLeftMargin:CGFloat         = 20
    
    var maxInterval:Int = -1
    var INTERVALS = CGFloat(HDPhoneMonitor.MAX_MINUTE_A_DAY / HDPhoneMonitor.MINUTES_PER_INTERVAL)
    
    let userDefault = NSUserDefaults()
    
    var isShowConnectionChart = false
    
    var settingsView: UIAlertController!
    
    //MARK:- Functions
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HDPhoneMonitorChartViewController.viewDidRotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        day = HDPhoneMonitor.getDayString(NSDate())
        initVariable()
        initControls()
        initView()
        loadData(day)
    }
    
    func initVariable() {
        if self.navigationController?.navigationBar.frame.height != nil {
            navigationBarHeight = (self.navigationController?.navigationBar.frame.height)!
        }
        statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
        if self.tabBarController?.tabBar.frame.height != nil {
            tabBarHeight = (self.tabBarController?.tabBar.frame.height)!
        }
        topMargin = navigationBarHeight + statusBarHeight
        botMargin = tabBarHeight
        
        if userDefault.valueForKey("isShowConnectionChart") != nil {
            isShowConnectionChart = userDefault.valueForKey("isShowConnectionChart") as! Bool
        }
    }
    
    func initControls() {
        // Navigation bar
        navigationItem.title = day
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.blackColor()]
        navigationController?.navigationBar.tintColor = UIColor.blackColor()
        
        // init next and back button
        let navigationButtonWidth:CGFloat = chartLeftMargin
        nextButton = UIButton(frame: CGRect(x: self.view.frame.width - navigationButtonWidth, y: topMargin, width: navigationButtonWidth, height: self.view.frame.height - topMargin - botMargin))
        nextButton.setTitle(">", forState: UIControlState.Normal)
        nextButton.setTitleColor(HDChartColor.GreenColor, forState: .Normal)
        nextButton.addTarget(self, action: #selector(HDPhoneMonitorChartViewController.toNextDay), forControlEvents: .TouchUpInside)
        self.view.addSubview(nextButton)
        backButton = UIButton(frame: CGRect(x: 0, y: topMargin, width: navigationButtonWidth, height: self.view.frame.height - topMargin - botMargin))
        backButton.setTitle("<", forState: .Normal)
        backButton.setTitleColor(HDChartColor.GreenColor, forState: .Normal)
        backButton.addTarget(self, action: #selector(HDPhoneMonitorChartViewController.toPreviousDay), forControlEvents: .TouchUpInside)
        self.view.addSubview(backButton)
        
        // No data label
        noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        noDataLabel.center = self.view.center
        noDataLabel.text = "No data :("
        noDataLabel.textColor = HDChartColor.GreyColor
        noDataLabel.font = UIFont.systemFontOfSize(20)
        self.view.backgroundColor = UIColor.whiteColor()
        
        // Setting button
        let settingsButton = UIBarButtonItem(title: "Settings", style: .Plain, target: self, action: #selector(HDPhoneMonitorChartViewController.onSettingsPressed))
        self.navigationItem.rightBarButtonItem = settingsButton
    }
    
    func onSettingsPressed() {
        presentViewController(settingsView, animated: true, completion: nil)
    }
    
    func initBatteryChartView() {
        lineChart = HDLineChart(frame: CGRectMake(
            chartLeftMargin,
            topMargin,
            self.view.frame.width - 2 * chartLeftMargin,
            self.view.frame.height - topMargin - botMargin
            ))
        lineChart.showLabel = true
        lineChart.backgroundColor = UIColor.clearColor()
        lineChart.lineWidth = 1.0
    }
    
    func initConnectionChartView() {
        if !isShowConnectionChart {
            return
        }
        
        barChart = HDBarChart(frame: CGRectMake(
            chartLeftMargin + 2 * lineChart.chartMargin,
            topMargin,
            self.view.frame.width - 2 * chartLeftMargin - 2 * lineChart.chartMargin,
            (self.view.frame.height - topMargin - botMargin)
            ))
    }
    
    func initSettingsView() {
        settingsView = UIAlertController(title: "Settings", message: nil, preferredStyle: .ActionSheet)
        let actionShowConnectionChart = UIAlertAction(title: "Show drop out chart", style: .Default) { (action: UIAlertAction) in
            self.showConnectionChart()
        }
        let actionHideConnectionChart = UIAlertAction(title: "Hide drop out chart", style: .Default) { (action: UIAlertAction) in
            self.hideConnectionChart()
        }
        let actionSync = UIAlertAction(title: "Sync to Google Sheet", style: .Default) { (action: UIAlertAction) in
            self.sync()
        }
        let actionChangeInterval = UIAlertAction(title: "Change interval", style: .Default) { (action: UIAlertAction) in
            let view = UIAlertController(title: "Change minutes per interval", message: "Please enter a number between 5 and 720", preferredStyle: .Alert)
            view.addTextFieldWithConfigurationHandler({ (textField: UITextField) in
                textField.keyboardType = UIKeyboardType.NumberPad
                textField.text = String(HDPhoneMonitor.MINUTES_PER_INTERVAL)
            })
            let actionCancel = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
            let actionOK = UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction) in
                let newValue = view.textFields?.first?.text!
                if HDPhoneMonitor.canChangeMinutesPerInterval(Int(newValue!)!) {
                    self.INTERVALS = CGFloat(HDPhoneMonitor.MAX_MINUTE_A_DAY / HDPhoneMonitor.MINUTES_PER_INTERVAL)
                    self.removeView()
                    self.initVariable()
                    self.initControls()
                    self.initView()
                    self.loadData(self.day)
                } else {
                    self.presentViewController(view, animated: true, completion: nil)
                }
            })
            view.addAction(actionCancel)
            view.addAction(actionOK)
            self.presentViewController(view, animated: true, completion: nil)
        }
        let actionCancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        if isShowConnectionChart {
            settingsView.addAction(actionHideConnectionChart)
        }
        else {
            settingsView.addAction(actionShowConnectionChart)
        }
        settingsView.addAction(actionSync)
        settingsView.addAction(actionChangeInterval)
        settingsView.addAction(actionCancel)
    }
    
    func initView() {
        // init chart
        initSettingsView()
        initBatteryChartView()
        initConnectionChartView()
    }
    
    func removeView() {
        removeBatteryChart()
        removeConnectionChart()
        removeControls()
    }
    
    func clearData() {
        phoneData.removeAll()
        connectionData.removeAll()
        isCharging.removeAll()
    }
    
    func removeBatteryChart() {
        if lineChart != nil {
            lineChart.removeFromSuperview()
        }
    }
    
    func removeConnectionChart() {
        if barChart != nil {
            barChart.removeFromSuperview()
        }
    }
    
    func removeControls() {
        if nextButton != nil {
            nextButton.removeFromSuperview()
        }
        if backButton != nil {
            backButton.removeFromSuperview()
        }
        if noDataLabel != nil {
            noDataLabel.removeFromSuperview()
        }
    }
    
    func loadMonitoringData(day: String) -> Bool {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let startDay:NSDate = dateFormatter.dateFromString("\(self.day) 00:00:00")!
        let endDay:NSDate = dateFormatter.dateFromString("\(self.day) 23:23:59")!
        let predicate = NSPredicate(format: "date >= %@ && date <= %@", startDay, endDay)
        
        let realm = try! Realm()
        mdata = realm.objects(MonitoringData.self).filter(predicate).sorted("date", ascending: true)
        
        if mdata!.count <= 0 {
            return false
        }
        
        adaptMonitoringData()
        
        return true
    }
    
    func adaptMonitoringData() {
        for log in mdata! {
            if log.interval() > maxInterval {
                maxInterval = log.interval()
            }
        }
        
        phoneData.removeAll()
        phoneData = [MonitoringData](count: maxInterval + 1, repeatedValue: MonitoringData())
        isCharging = [Bool](count: maxInterval + 1, repeatedValue: false)
        
        for index in 0 ..< mdata!.count {
            let i = mdata!.count - 1 - index
            phoneData[mdata![i].interval()] = mdata![i]
            
            if mdata![index].chargingStatus {
                let interval = mdata![index].interval()
                isCharging[interval] = true
            }
        }
        
        //normalizeData()
        for index in 0 ..< phoneData.count - 1 {
            if isCharging[index] {
                if phoneData[index].batteryLevel < phoneData[index + 1].batteryLevel {
                    isCharging[index + 1] = true
                }
            }
            
            if phoneData[index].chargingStatus && !phoneData[index + 1].chargingStatus {
                if phoneData[index].batteryLevel >= phoneData[index + 1].batteryLevel {
                    let pData = phoneData[index]
                    phoneData[index] = MonitoringData(
                        value: [
                            "date": pData.date,
                            "batteryLevel": pData.batteryLevel,
                            "memoryUsage": pData.memoryUsage,
                            "chargingStatus": false
                        ])
                }
            }
        }

    }
    
    func loadConnectionData(day: String) -> Bool {
        if !isShowConnectionChart {
            return true
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let startDay:NSDate = dateFormatter.dateFromString("\(self.day) 00:00:00")!
        let endDay:NSDate = dateFormatter.dateFromString("\(self.day) 23:23:59")!
        let realm = try! Realm()
        let cpredicate = NSPredicate(format: "date >= %@ && date <= %@ && status = 'Disconnected'", startDay, endDay)
        cdata = realm.objects(ConnectionData.self).filter(cpredicate).sorted("date", ascending: true)
        
        
        
        if cdata!.count <= 0 {
            return false
        }
        
        adaptConnectionData()
        
        
        return true
    }
    
    func adaptConnectionData() {
        if cdata != nil && cdata!.count > 0 {
            connectionData.removeAll()
            connectionData = [Int](count: maxInterval + 1, repeatedValue: 0)
            for log in cdata! {
                connectionData[log.interval()] += 1
            }
        }
    }
    
    func loadData(day: String) {
        // load log data from Realm
        if loadMonitoringData(day) && loadConnectionData(day) {
            addChart()
        }
        else {
            self.view.addSubview(noDataLabel)
        }
    }
    
    func addConnectionChart() {
        if !isShowConnectionChart {
            return
        }
        
        barChart.backgroundColor = UIColor.clearColor()
        
        barChart.labelMarginTop = 0.0
        barChart.xLabels = [String](count: Int(INTERVALS), repeatedValue: "")
        barChart.yValues = connectionData
        barChart.strokeChart()
        
        self.view.addSubview(barChart)
    }
    
    func addBatteryChart() {
        // load battery data to chart
        let batteryLogData:HDLineChartData = HDLineChartData()
        batteryLogData.color = HDChartColor.RedColor
        batteryLogData.itemCount = phoneData.count
        batteryLogData.getData = ({(index: Int) -> HDLineChartDataItem in
            var yValue:CGFloat = -1
            if !self.phoneData[index].chargingStatus {
                yValue = CGFloat(self.phoneData[index].batteryLevel)
            }
            let item = HDLineChartDataItem(y: yValue)
            return item
        })
        
        // load memory usage data to chart
        let memoryUsageData:HDLineChartData = HDLineChartData()
        memoryUsageData.color = HDChartColor.PurpleColor
        memoryUsageData.itemCount = phoneData.count
        memoryUsageData.getData = ({(index: Int) -> HDLineChartDataItem in
            let yValue:CGFloat = CGFloat(self.phoneData[index].memoryUsage)
            let item = HDLineChartDataItem(y: yValue)
            return item
        })
        
        // load battery state to chart
        let chargingData:HDLineChartData = HDLineChartData()
        chargingData.color = HDChartColor.GreenColor
        chargingData.itemCount = phoneData.count
        chargingData.getData = ({(index: Int) -> HDLineChartDataItem in
            var yValue:CGFloat = -1
            if self.isCharging[index] {
                yValue = CGFloat(self.phoneData[index].batteryLevel)
            }
            let item = HDLineChartDataItem(y: yValue)
            return item
        })
        
        lineChart.showLegend = true
        lineChart.legends = ["Batttery Level (%)", "Charging", "Memory Usage (MB)"]
        
        
        lineChart.xValueCount = INTERVALS
        lineChart.xLabels = ["0", "3", "6", "9", "12", "15", "18", "21"]
        
        lineChart.chartData = [batteryLogData, chargingData, memoryUsageData]
        
        lineChart.strokeChart()
        
        self.view.addSubview(lineChart)
    }
    
    func addChart() {
        addConnectionChart()
        addBatteryChart()
    }
    
    func viewDidRotated() {
        removeView()
        initVariable()
        initControls()
        initView()
        loadData(day)
    }
    
    func jumpDay(day: String, daysToJump value:Double) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        let d = dateFormatter.dateFromString(day)
        let nd = d?.dateByAddingTimeInterval(value * 60*60*24)
        return dateFormatter.stringFromDate(nd!)
    }
    
    func toNextDay() {
        // date = next date
        day = jumpDay(day, daysToJump: 1)
        clearData()
        // refresh view
        removeView()
        initVariable()
        initControls()
        initView()
        loadData(day)
    }
    
    func toPreviousDay() {
        // date  = previous date
        day = jumpDay(day, daysToJump: -1)
        clearData()
        // refresh view
        removeView()
        initVariable()
        initControls()
        initView()
        loadData(day)
    }
    
    func showConnectionChart() {
        isShowConnectionChart = true
        userDefault.setValue(isShowConnectionChart, forKey: "isShowConnectionChart")
        userDefault.synchronize()
        
        self.initConnectionChartView()
        self.loadConnectionData(day)
        self.addConnectionChart()
        initSettingsView()
    }
    
    func hideConnectionChart() {
        isShowConnectionChart = false
        userDefault.setValue(isShowConnectionChart, forKey: "isShowConnectionChart")
        userDefault.synchronize()
        
        self.removeConnectionChart()
        initSettingsView()
    }
    
    func sync() {
        GoogleSheetService.sharedService.delegate = self
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(
            GoogleSheetService.kKeychainItemName,
            clientID: GoogleSheetService.kClientID,
            clientSecret: nil) {
            GoogleSheetService.sharedService.authorizer = auth
        }
        if let authorizer = GoogleSheetService.sharedService.authorizer,
            canAuth = authorizer.canAuthorize where canAuth {
            if GoogleSheetService.spreadsheetId != nil {
                ControllerHelper.showProgressDialog("Syncing", viewcontroller: self)
                GoogleSheetService.sharedService.sync()
            }
            else {
                ControllerHelper.showProgressDialog("Creating spreadsheet", viewcontroller: self)
                GoogleSheetService.sharedService.createSpreadSheet()
            }
        } else {
            ControllerHelper.chartViewController = self
            presentViewController(
                ControllerHelper.createAuthController(),
                animated: true,
                completion: nil
            )
        }
        
    }
}

extension HDPhoneMonitorChartViewController: GoogleSheetServiceDelegate {
    func didSync(object: GTLObject, error: NSError?) {
        self.navigationItem.rightBarButtonItem?.enabled = true
        self.navigationItem.leftBarButtonItem?.enabled = true
        if let error = error {
            ControllerHelper.handleError(error, viewcontroller: self)
        }
        else {
            //print("--------Successfully---------")
            SVProgressHUD.showSuccessWithStatus("Synced")
        }
    }
    
    func didCreateSpreadSheet(object: GTLObject, error: NSError?) {
        if let error = error {
            ControllerHelper.handleError(error, viewcontroller: self)
        }
        else {
            // sync
            //SVProgressHUD.showSuccessWithStatus("Created spreadsheet")
            GoogleSheetService.spreadsheetId = object.JSON["spreadsheetId"]! as? String
            userDefault.setValue(object.JSON["spreadsheetId"]!, forKey: "spreadsheetId")
            userDefault.synchronize()
            self.sync()
        }
    }
}
