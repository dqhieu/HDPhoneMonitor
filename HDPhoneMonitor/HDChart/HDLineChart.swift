//
//  HDLineChart.swift
//  HDPhoneMonitor
//
//  Created by Dinh Quang Hieu on 7/20/16.
//  Copyright © 2016 Dinh Quang Hieu. All rights reserved.
//

import UIKit
import QuartzCore

public class HDLineChart: UIView {
    
    public var xLabels: NSArray = []{
        didSet{
            
            if showLabel {
                
                xLabelWidth = chartCavanWidth! / CGFloat(xLabels.count)
                
                for index in 0 ..< xLabels.count {
                    
                    let labelText = xLabels[index] as! NSString
                    let labelX = 2.0 * chartMargin +  ( CGFloat(index) * xLabelWidth) - (xLabelWidth / 2.0)
                    let label:HDChartLabel = HDChartLabel(frame: CGRect(x:  labelX, y: chartMargin + chartCavanHeight!, width: xLabelWidth, height: chartMargin))
                    label.textAlignment = NSTextAlignment.Center
                    label.text = labelText as String
                    addSubview(label)
                }
            }else {
                xLabelWidth = frame.size.width / CGFloat(xLabels.count)
            }
        }
    }
    
    public var yLabels: NSArray = []{
        didSet{
            
            yLabelNum = CGFloat(yLabels.count)
            //let yStep:CGFloat = (yValueMax - yValueMin) / CGFloat(yLabelNum)
            let yStep:CGFloat = 10.0
            //let yStepHeight:CGFloat  = chartCavanHeight! / CGFloat(yLabelNum)
            let yStepHeight:CGFloat = chartCavanHeight! / yStep
            
            var index:CGFloat = 0
            
            for _ in yLabels
            {
                
                yValueMin = 0.0
                let labelY = chartCavanHeight - (index * yStepHeight)
                let label: HDChartLabel = HDChartLabel(frame: CGRect(x: 0.0, y: CGFloat(labelY), width: CGFloat(chartMargin + 5.0), height: CGFloat(yLabelHeight) ) )
                label.textAlignment = NSTextAlignment.Right
                label.text = NSString(format:yLabelFormat, Double(yValueMin + (yStep * index))) as String
                ++index
                addSubview(label)
            }
        }
    }
    
    public var legends: NSArray = [] {
        didSet {
            chartCavanHeight! -= legendHeight
            for (index, legend) in legends.enumerate() {
                let labelHeight:CGFloat = 15
                let labelWidth:CGFloat = chartCavanWidth / CGFloat(legends.count) * 2 / 3
                let labelOffset:CGFloat = chartCavanWidth / CGFloat(legends.count) / 3
                let label: HDChartLabel = HDChartLabel(frame: CGRect(x: labelOffset + CGFloat(index) * (labelWidth + labelOffset), y: chartMargin + chartCavanHeight! + legendHeight, width: labelWidth, height: labelHeight))
                label.textAlignment = NSTextAlignment.Left
                label.text = legend as! String
                addSubview(label)
            }
        }
    }
    
    /**
     * Array of `LineChartData` objects, one for each line.
     */
    
    public var chartData: NSArray = []{
        didSet{
            let yLabelsArray:NSMutableArray = NSMutableArray(capacity: chartData.count)
            var yMax:CGFloat = 0.0
            var yMin:CGFloat = CGFloat.max
            var yValue:CGFloat!
            
            // remove all shape layers before adding new ones
            for layer : AnyObject in chartLineArray{
                (layer as! CALayer).removeFromSuperlayer()
            }
            for layer : AnyObject in chartLegendArray {
                (layer as! CALayer).removeFromSuperlayer()
            }
            
            chartLineArray = NSMutableArray(capacity: chartData.count)
            chartLegendArray = NSMutableArray(capacity: chartData.count)
            
            // set for point stoken
            let circle_stroke_width:CGFloat = 2.0
            let line_width:CGFloat = lineWidth
            
            for chart : AnyObject in chartData{
                // create as many chart line layers as there are data-lines
                let chartObj = chart as! HDLineChartData
                let chartLine:CAShapeLayer = CAShapeLayer()
                chartLine.lineCap       = kCALineCapButt
                chartLine.lineJoin      = kCALineJoinMiter
                chartLine.fillColor     = UIColor.whiteColor().CGColor
                chartLine.lineWidth     = line_width
                chartLine.strokeEnd     = 0.0
                layer.addSublayer(chartLine)
                chartLineArray.addObject(chartLine)
                
                // create legend
                let chartLegend:CAShapeLayer = CAShapeLayer()
                chartLegend.lineCap       = kCALineCapButt
                chartLegend.lineJoin      = kCALineJoinMiter
                chartLegend.fillColor     = UIColor.whiteColor().CGColor
                chartLegend.lineWidth     = line_width
                chartLegend.strokeEnd     = 0.0
                layer.addSublayer(chartLegend)
                chartLegendArray.addObject(chartLegend)
                
                for i in 0 ..< chartObj.itemCount{
                    yValue = CGFloat(chartObj.getData(i).y)
                    yLabelsArray.addObject(NSString(format: "%2f", yValue))
                    yMax = fmax(yMax, yValue)
                    yMin = fmin(yMin, yValue)
                }
            }
            
            // Min value for Y label
            if yMax < 5 {
                yMax = 5.0
            }
            
            if yMin < 0{
                yMin = 0.0
            }
            
            yValueMin = yMin;
            yValueMax = yMax;
            
            
            if showLabel {
                //print("show y label")
                yLabels = yLabelsArray as NSArray
            }
            
            setNeedsDisplay()
            
        }
    }
    
    var pathPoints: NSMutableArray = []
    
    //For legend
    
    public var legendHeight:CGFloat = 15.0
    
    public var showLegend: Bool = false
    //For X
    
    public var xLabelWidth:CGFloat = 0.0
    
    public var xValueCount:CGFloat = 0.0
    
    //For Y
    
    public var yValueMax:CGFloat = 10.0
    
    public var yValueMin:CGFloat = 1.0
    
    public var yLabelNum:CGFloat = 0.0
    
    public var yLabelHeight:CGFloat = 12.0
    
    //For Chart
    
    public var chartCavanHeight:CGFloat!
    
    public var chartCavanWidth:CGFloat!
    
    public var chartMargin:CGFloat = 25.0
    
    public var showLabel: Bool = true
    
    public var showCoordinateAxis: Bool = true
    
    // For Axis
    
    public var axisColor:UIColor = HDGreyColor
    
    public var axisWidth:CGFloat = 1.0
    
    public var xUnit: NSString!
    
    public var yUnit: NSString!
    
    public var lineWidth: CGFloat! = 1.0
    
    /**
     *  String formatter for float values in y labels. If not set, defaults to @"%1.f"
     */
    
    public var yLabelFormat:NSString = "%.0f"
    
    var chartLineArray: NSMutableArray = []  // Array[CAShapeLayer]
    var chartLegendArray: NSMutableArray = []
    
    var chartPaths: NSMutableArray = []     // Array of line path, one for each line.
    
    //public var delegate:HDChartDelegate?
    
    
    // MARK: Functions
    
    func setDefaultValues() {
        backgroundColor = UIColor.whiteColor()
        clipsToBounds = true
        chartLineArray = NSMutableArray()
        chartLegendArray = NSMutableArray()
        showLabel = false
        pathPoints = NSMutableArray()
        userInteractionEnabled = true
        
        chartCavanWidth = frame.size.width - (chartMargin * 2.0)
        chartCavanHeight = frame.size.height - (chartMargin * 2.0)
    }
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        touchPoint(touches, withEvent: event)
        touchKeyPoint(touches, withEvent: event)
    }
    
    override public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        touchPoint(touches, withEvent: event)
        touchKeyPoint(touches, withEvent: event)
    }
    
    func touchPoint(touches: NSSet!, withEvent event: UIEvent!){
        let touch:UITouch = touches.anyObject() as! UITouch
        let touchPoint = touch.locationInView(self)
        
        for linePoints:AnyObject in pathPoints {
            let linePointsArray = linePoints as! NSArray
            
            for i:NSInteger in 0 ..< (linePointsArray.count - 1){
                
                let p1:CGPoint = (linePointsArray[i] as! HDValue).point
                let p2:CGPoint = (linePointsArray[i+1] as! HDValue).point
                
                
                
                // Closest distance from point to line
                var distance:CGFloat = fabs(((p2.x - p1.x) * (touchPoint.y - p1.y)) - ((p1.x - touchPoint.x) * (p1.y - p2.y)))
                distance =  distance /  hypot( p2.x - p1.x,  p1.y - p2.y )
                
                
                if distance <= 5.0 {
                    // Conform to delegate parameters, figure out what bezier path this CGPoint belongs to.
                    
                    for path : AnyObject in chartPaths {
                        
                        let pointContainsPath:Bool = CGPathContainsPoint((path as! UIBezierPath).CGPath, nil, p1, false)
                        
                        if pointContainsPath {
                            
                            //delegate?.userClickedOnLinePoint(touchPoint , lineIndex: chartPaths.indexOfObject(path))
                        }
                    }
                }
                
                
            }
            
            
        }
    }
    
    
    func touchKeyPoint(touches: NSSet!, withEvent event: UIEvent!){
        let touch:UITouch = touches.anyObject() as! UITouch
        let touchPoint = touch.locationInView(self)
        
        for linePoints: AnyObject in pathPoints {
            let linePointsArray: NSArray = pathPoints as NSArray
            
            for i:NSInteger in 0 ..< (linePointsArray.count - 1){
                let p1:CGPoint = (linePointsArray[i] as! HDValue).point
                let p2:CGPoint = (linePointsArray[i+1] as! HDValue).point
                
                let distanceToP1: CGFloat = fabs( CGFloat( hypot( touchPoint.x - p1.x , touchPoint.y - p1.y ) ))
                let distanceToP2: CGFloat = hypot( touchPoint.x - p2.x, touchPoint.y - p2.y)
                
                let distance: CGFloat = fmin(distanceToP1, distanceToP2)
                
                if distance <= 10.0 {
                    
                    //delegate?.userClickedOnLineKeyPoint(touchPoint , lineIndex: pathPoints.indexOfObject(linePoints) ,keyPointIndex:(distance == distanceToP2 ? i + 1 : i) )
                }
            }
        }
        
    }
    
    /**
     * This method will call and troke the line in animation
     */
    
    public func strokeChart(){
        chartPaths = NSMutableArray()
        
        //Draw each line
        for lineIndex in 0 ..< chartData.count {
            let chartData:HDLineChartData = self.chartData[lineIndex] as! HDLineChartData
            let chartLine:CAShapeLayer = chartLineArray[lineIndex] as! CAShapeLayer
            let chartLegend:CAShapeLayer = chartLegendArray[lineIndex] as! CAShapeLayer
            
            var yValue:CGFloat?
            var innerGrade:CGFloat?
            
            UIGraphicsBeginImageContext(frame.size)
            
            let progressline:UIBezierPath = UIBezierPath()
            progressline.lineWidth = chartData.lineWidth
            progressline.lineCapStyle = CGLineCap.Round
            progressline.lineJoinStyle = CGLineJoin.Round
            
            let progressLegend:UIBezierPath = UIBezierPath()
            progressLegend.lineWidth = chartData.lineWidth
            progressLegend.lineCapStyle = CGLineCap.Round
            progressLegend.lineJoinStyle = CGLineJoin.Round
            
            chartPaths.addObject(progressLegend)
            chartPaths.addObject(progressline)
            
            if !showLabel {
                chartCavanHeight = frame.size.height - 2 * yLabelHeight
                chartCavanWidth = frame.size.width
                chartMargin = 0.0
                xLabelWidth = (chartCavanWidth! / CGFloat(xValueCount - 1))
            } else {
                xLabelWidth = chartCavanWidth! / CGFloat(xValueCount)
            }
            
            var last_y:CGFloat = -1
            
            for i:Int in 0 ..< chartData.itemCount {
                yValue = CGFloat(chartData.getData(i).y)
                
                
                innerGrade = (yValue! - yValueMin) / (yValueMax - yValueMin)
                
                let x:CGFloat = 2.0 * chartMargin +  (CGFloat(i) * xLabelWidth)
                let y:CGFloat = chartCavanHeight! - (innerGrade! * chartCavanHeight!) + (yLabelHeight / 2.0)
                
                if yValue == -1 {
                    progressline.moveToPoint(CGPointMake(x, y))
                    last_y = yValue!
                    continue
                }
                
                if last_y != -1 {
                    progressline.addLineToPoint(CGPointMake(x, y))
                }
                
                progressline.moveToPoint(CGPointMake(x, y))
                last_y = yValue!
            }
            
            let labelHeight:CGFloat = 15
            let labelWidth:CGFloat = chartCavanWidth / CGFloat(legends.count) * 2 / 3
            let labelOffset:CGFloat = chartCavanWidth / CGFloat(legends.count) / 3
            
            let x1:CGFloat = CGFloat((lineIndex) * Int(chartCavanWidth!) / legends.count)
            let y1:CGFloat = chartMargin + chartCavanHeight! + legendHeight * 3/2
            let x2:CGFloat = labelOffset + CGFloat(lineIndex) * (labelWidth + labelOffset) - 10
            let y2:CGFloat = chartMargin + chartCavanHeight! + legendHeight * 3/2
            
            progressLegend.moveToPoint(CGPointMake(CGFloat(x1), CGFloat(y1)))
            progressLegend.addLineToPoint(CGPointMake(CGFloat(x2), CGFloat(y2)))
            
            // setup the color of the chart line
            if chartData.color != UIColor.blackColor() {
                chartLine.strokeColor = chartData.color.CGColor
                chartLegend.strokeColor = chartData.color.CGColor
            }
            else {
                chartLine.strokeColor = HDGreenColor.CGColor
                chartLegend.strokeColor = HDGreenColor.CGColor
            }
            
            progressline.stroke()
            progressLegend.stroke()
            
            chartLine.path = progressline.CGPath
            chartLegend.path = progressLegend.CGPath
            
            CATransaction.begin()
            let pathAnimation:CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
            pathAnimation.duration = 1.0
            pathAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            pathAnimation.fromValue = 0.0
            pathAnimation.toValue   = 1.0
            
            chartLine.addAnimation(pathAnimation, forKey:"strokeEndAnimation")
            chartLine.strokeEnd = 1.0
            
            chartLegend.addAnimation(pathAnimation, forKey:"strokeEndAnimation")
            chartLegend.strokeEnd = 1.0
            
            CATransaction.commit()
            
            UIGraphicsEndImageContext()
        }
        
    }
    
    // Draw axis
    override public func drawRect(rect: CGRect)
    {
        if showCoordinateAxis {
            
            let yAsixOffset:CGFloat = 10.0
            
            let ctx:CGContextRef = UIGraphicsGetCurrentContext()!
            UIGraphicsPushContext(ctx)
            CGContextSetLineWidth(ctx, axisWidth)
            CGContextSetStrokeColorWithColor(ctx, axisColor.CGColor)
            
            let xAxisWidth:CGFloat = CGRectGetWidth(rect) - chartMargin/2.0
            let yAxisHeight:CGFloat = chartMargin + chartCavanHeight!
            
            // draw coordinate axis
            CGContextMoveToPoint(ctx, chartMargin + yAsixOffset, 0)
            CGContextAddLineToPoint(ctx, chartMargin + yAsixOffset, yAxisHeight)
            CGContextAddLineToPoint(ctx, yAsixOffset + xAxisWidth, yAxisHeight)
            //CGContextAddLineToPoint(ctx, yAsixOffset + xAxisWidth, 0) // draw y-right axis
            CGContextStrokePath(ctx)
            
            
            // draw y axis arrow
            CGContextMoveToPoint(ctx, chartMargin + yAsixOffset - 3, 6)
            CGContextAddLineToPoint(ctx, chartMargin + yAsixOffset, 0)
            CGContextAddLineToPoint(ctx, chartMargin + yAsixOffset + 3, 6)
            CGContextStrokePath(ctx)
            
            /*
             // draw z axis arrow (z axis means the y-right axis)
             CGContextMoveToPoint(ctx, yAsixOffset + xAxisWidth - 3, 6)
             CGContextAddLineToPoint(ctx, yAsixOffset + xAxisWidth, 0)
             CGContextAddLineToPoint(ctx, yAsixOffset + xAxisWidth + 3, 6)
             CGContextStrokePath(ctx)*/
            
            
            
            // draw x axis arrow
            CGContextMoveToPoint(ctx, yAsixOffset + xAxisWidth - 6, yAxisHeight - 3)
            CGContextAddLineToPoint(ctx, yAsixOffset + xAxisWidth, yAxisHeight)
            CGContextAddLineToPoint(ctx, yAsixOffset + xAxisWidth - 6, yAxisHeight + 3);
            CGContextStrokePath(ctx)
            
            
            if showLabel{
                
                // draw x axis separator
                var point:CGPoint!
                xLabelWidth = chartCavanWidth! / CGFloat(xLabels.count)
                for i:Int in 0 ..< xLabels.count {
                    point = CGPointMake(2 * chartMargin +  ( CGFloat(i) * xLabelWidth), chartMargin + chartCavanHeight!)
                    CGContextMoveToPoint(ctx, point.x, point.y - 2)
                    CGContextAddLineToPoint(ctx, point.x, point.y)
                    CGContextStrokePath(ctx)
                }
                
                // draw y axis separator
                let yStep:CGFloat = 10.0
                let yStepHeight:CGFloat = chartCavanHeight! / yStep
                for i:Int in 0 ..< Int(xValueCount) {
                    point = CGPointMake(chartMargin + yAsixOffset, (chartCavanHeight! - CGFloat(i) * yStepHeight + yLabelHeight/2.0
                    ))
                    CGContextMoveToPoint(ctx, point.x, point.y)
                    CGContextAddLineToPoint(ctx, point.x + 2, point.y)
                    CGContextStrokePath(ctx)
                }
            }
            
            let font:UIFont = UIFont.systemFontOfSize(11)
            // draw legends
            
            
            
            /*
             // draw y unit
             if yUnit != nil{
             let height:CGFloat = heightOfString(yUnit, width: 30.0, font: font)
             let drawRect:CGRect = CGRectMake(chartMargin + 10 + 5, 0, 30.0, height)
             drawTextInContext(ctx, text:yUnit, rect:drawRect, font:font)
             }
             
             // draw x unit
             if xUnit != nil {
             let height:CGFloat = heightOfString(yUnit, width:30.0, font:font)
             let drawRect:CGRect = CGRectMake(CGRectGetWidth(rect) - chartMargin + 5, chartMargin + chartCavanHeight! - height/2, 25.0, height)
             drawTextInContext(ctx, text:yUnit, rect:drawRect, font:font)
             }*/
        }
        
        super.drawRect(rect)
    }
    /*
     func heightOfString(text: NSString, width: CGFloat, font: UIFont) -> CGFloat{
     let size : CGSize = CGSizeMake(width, CGFloat.max)
     let rect : CGRect = text.boundingRectWithSize(size, options: NSStringDrawingOptions.UsesFontLeading , attributes: [NSFontAttributeName : font], context: nil)
     return rect.size.height
     }
     
     func drawTextInContext(ctx: CGContextRef, text: NSString!, rect: CGRect, font:UIFont){
     let priceParagraphStyle:NSMutableParagraphStyle = NSParagraphStyle.defaultParagraphStyle() as! NSMutableParagraphStyle
     priceParagraphStyle.lineBreakMode = NSLineBreakMode.ByTruncatingTail
     priceParagraphStyle.alignment = NSTextAlignment.Left
     
     text.drawInRect(rect, withAttributes: [ NSParagraphStyleAttributeName:priceParagraphStyle, NSFontAttributeName:font] )
     }*/
    
    // MARK: Init
    
    override public init(frame: CGRect){
        super.init(frame: frame)
        setDefaultValues()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}