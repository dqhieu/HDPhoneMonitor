//
//  HDLineChartData.swift
//  HDPhoneMonitor
//
//  Created by Dinh Quang Hieu on 7/20/16.
//  Copyright © 2016 Dinh Quang Hieu. All rights reserved.
//

import UIKit

public class HDLineChartDataItem{
    var y:CGFloat = 0.0
    
    public init(){
    }
    
    public init(y : CGFloat){
        self.y = y;
    }
}


public  class HDLineChartData{
    public var getData = ({(index: Int) -> HDLineChartDataItem in
        return HDLineChartDataItem()
    })
    
    public var color:UIColor = UIColor.grayColor()
    public var itemCount:Int = 0
    public var lineWidth:CGFloat = 2.0
    
    public init(){
        
    }
}