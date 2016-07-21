//
//  HDPhoneMonitorChartViewController.swift
//  HDPhoneMonitor
//
//  Created by Dinh Quang Hieu on 7/20/16.
//  Copyright © 2016 Dinh Quang Hieu. All rights reserved.
//

import UIKit
import RealmSwift

class HDPhoneMonitorChartViewController: UIViewController {
    
    var lineChart:HDLineChart!
    var phoneLogs:[Log] = []
    
    var nextButton:UIButton!
    var backButton:UIButton!
    
    var day: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HDPhoneMonitorChartViewController.viewDidRotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        day = HDPhoneMonitor.getDate()
        
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
        lineChart.backgroundColor = UIColor.clearColor()
        lineChart.lineWidth = 2.0
        //lineChart.legendStyle = HDLegendItemStyleSerial;
        //lineChart.legendFontSize = 12.0;
        
        navigationItem.title = day
        // init next and back button
        nextButton = UIButton(frame: CGRect(x: self.view.frame.width - navigationButtonWidth, y: topMargin, width: navigationButtonWidth, height: self.view.frame.height - topMargin - botMargin))
        nextButton.setTitle(">", forState: UIControlState.Normal)
        nextButton.setTitleColor(HDGreenColor, forState: .Normal)
        nextButton.addTarget(self, action: #selector(HDPhoneMonitorChartViewController.toNextDay), forControlEvents: .TouchUpInside)
        self.view.addSubview(nextButton)
        backButton = UIButton(frame: CGRect(x: 0, y: topMargin, width: navigationButtonWidth, height: self.view.frame.height - topMargin - botMargin))
        backButton.setTitle("<", forState: .Normal)
        backButton.setTitleColor(HDGreenColor, forState: .Normal)
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
        let realm = try! Realm()
        let predicate = NSPredicate(format: "date = %@", day)
        let logs = realm.objects(Log.self).filter(predicate)
        
        if logs.count <= 0 {
            print("No logs")
            let alert = UIAlertController(title: "No data", message: nil, preferredStyle: .Alert)
            let actionOk = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(actionOk)
            presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        //print(logs)
        
        var startIndex:Int! = logs.count
        var endIndex:Int! = -1
        
        for log in logs {
            if log.interval > endIndex {
                endIndex = log.interval
            }
            if log.interval < startIndex {
                startIndex = log.interval
            }
            
        }
        
        phoneLogs.removeAll()
        phoneLogs = [Log](count: endIndex + 1, repeatedValue: Log())
        
        for log in logs {
            phoneLogs[log.interval] = log
        }
        
        
        // load battery data to chart
        let batteryLogData:HDLineChartData = HDLineChartData()
        batteryLogData.color = HDGreenColor
        batteryLogData.itemCount = phoneLogs.count
        batteryLogData.getData = ({(index: Int) -> HDLineChartDataItem in
            let yValue:CGFloat = CGFloat(self.phoneLogs[index].batteryLevel)
            let item = HDLineChartDataItem(y: yValue)
            return item
        })
        
        // load memory usage data to chart
        let memoryUsageData:HDLineChartData = HDLineChartData()
        memoryUsageData.color = HDPurpleColor
        memoryUsageData.itemCount = phoneLogs.count
        memoryUsageData.getData = ({(index: Int) -> HDLineChartDataItem in
            let yValue:CGFloat = CGFloat(self.phoneLogs[index].memoryUsage)
            let item = HDLineChartDataItem(y: yValue)
            return item
        })
        
        //
        
        lineChart.showLegend = true
        lineChart.legends = ["Batttery Level (%)", "Memory Usage (MB)"]
        
        lineChart.xValueCount = 288 // number of interval in day
        lineChart.xLabels = ["0", "3", "6", "9", "12", "15", "18", "21", "23"]
        
        lineChart.chartData = [batteryLogData, memoryUsageData]
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
