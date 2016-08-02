//
//  HDChartLabel.swift
//  HDPhoneMonitor
//
//  Created by Dinh Quang Hieu on 7/20/16.
//  Copyright © 2016 Dinh Quang Hieu. All rights reserved.
//

import UIKit

public class HDChartLabel: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        font = UIFont.boldSystemFontOfSize(10.0)
        textColor = HDChartColor.GreyColor
        backgroundColor = UIColor.clearColor()
        textAlignment = NSTextAlignment.Center
        userInteractionEnabled = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}