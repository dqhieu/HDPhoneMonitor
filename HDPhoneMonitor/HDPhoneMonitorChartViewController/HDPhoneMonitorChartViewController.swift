//
//  HDPhoneMonitorChartViewController.swift
//  HDPhoneMonitor
//
//  Created by Dinh Quang Hieu on 7/20/16.
//  Copyright © 2016 Dinh Quang Hieu. All rights reserved.
//

import UIKit
import RealmSwift

public class HDPhoneMonitorChartViewController: UIViewController {
    
    //MARK:- Variables
    
    var lineChart:HDLineChart!
    var phoneData:[MonitoringData] = []
    var connectionData:[ConnectionData] = []
    
    var nextButton:UIButton!
    var backButton:UIButton!
    
    var day: String!
    
    //MARK:- Functions
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HDPhoneMonitorChartViewController.viewDidRotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        day = HDPhoneMonitor.getDayString(NSDate())
        
        initView()
        loadData(day)
    }
    
    func initView() {
        // init chart
        let navigationBarHeight: CGFloat? = self.navigationController?.navigationBar.frame.height
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
        let tabBarHeight: CGFloat? = self.tabBarController?.tabBar.frame.height
        var topMargin:CGFloat = 0
        if navigationBarHeight != nil {
            topMargin = navigationBarHeight! + statusBarHeight
        }
        var botMargin:CGFloat = 0
        if tabBarHeight != nil {
            botMargin = tabBarHeight!
        }
        
        let navigationButtonWidth:CGFloat = 20
        
        lineChart = HDLineChart(frame: CGRectMake(navigationButtonWidth,  topMargin, self.view.frame.width - 2 * navigationButtonWidth, self.view.frame.height - topMargin - botMargin))
        lineChart.showLabel = true
        lineChart.backgroundColor = UIColor.whiteColor()
        lineChart.lineWidth = 2.0
        
        navigationItem.title = day
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.blackColor()]
        navigationController?.navigationBar.tintColor = UIColor.blackColor()
        // init next and back button
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
    }
    
    func removeView() {
        if lineChart != nil {
            lineChart.removeFromSuperview()
        }
        if nextButton != nil {
            nextButton.removeFromSuperview()
        }
        if backButton != nil {
            backButton.removeFromSuperview()
        }
    }
    
    func loadData(day: String) {
        // load log data from Realm
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let startDay:NSDate = dateFormatter.dateFromString("\(self.day) 00:00:00")!
        let endDay:NSDate = dateFormatter.dateFromString("\(self.day) 23:23:59")!
        let predicate = NSPredicate(format: "date >= %@ && date <= %@", startDay, endDay)
        
        let realm = try! Realm()
        let data = realm.objects(MonitoringData.self).filter(predicate).sorted("date", ascending: true)
        
        if data.count <= 0 {
            let alert = UIAlertController(title: "No data", message: nil, preferredStyle: .Alert)
            let actionOk = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(actionOk)
            presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        //print(logs)
        
        var startIndex:Int! = data.count
        var endIndex:Int! = -1
        
        for log in data {
            if log.interval() > endIndex {
                endIndex = log.interval()
            }
            if log.interval() < startIndex {
                startIndex = log.interval()
            }
        }
        
        phoneData.removeAll()
        phoneData = [MonitoringData](count: endIndex + 1, repeatedValue: MonitoringData())
        
        for log in data {
            phoneData[log.interval()] = log
        }
        
        // load connection data
        let cdata = realm.objects(ConnectionData.self).filter(predicate).sorted("date", ascending: true)
        if cdata.count > 0 {
            
        }
        
    }
    
    func addChart() {
        // load battery data to chart
        let batteryLogData:HDLineChartData = HDLineChartData()
        batteryLogData.color = HDChartColor.RedColor
        batteryLogData.itemCount = phoneData.count
        batteryLogData.getData = ({(index: Int) -> HDLineChartDataItem in
            let yValue:CGFloat = CGFloat(self.phoneData[index].batteryLevel)
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
            if self.phoneData[index].chargingStatus {
                yValue = CGFloat(self.phoneData[index].batteryLevel)
            }
            let item = HDLineChartDataItem(y: yValue)
            return item
        })
        
        lineChart.showLegend = true
        lineChart.legends = ["Batttery Level (%)", "Memory Usage (MB)", "Charging"]
        
        let intervals = CGFloat(HDPhoneMonitor.MAX_MINUTE_A_DAY / HDPhoneMonitor.MINUTES_PER_INTERVAL)
        lineChart.xValueCount = intervals
        lineChart.xLabels = ["0", "3", "6", "9", "12", "15", "18", "21"]
        
        lineChart.chartData = [batteryLogData, memoryUsageData, chargingData]
        lineChart.strokeChart()
        
        self.view.addSubview(lineChart)
    }
    
    func viewDidRotated()
    {
        removeView()
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
        print(day)
        print("Next")
        // refresh view
        removeView()
        initView()
        loadData(day)
    }
    
    func toPreviousDay() {
        // date  = previous date
        day = jumpDay(day, daysToJump: -1)
        print(day)
        print("Back")
        // refresh view
        removeView()
        initView()
        loadData(day)
    }
    
    
}
