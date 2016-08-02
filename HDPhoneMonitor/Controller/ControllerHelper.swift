//
//  Helper.swift
//  HDPhoneMonitor
//
//  Created by Dinh Quang Hieu on 8/2/16.
//  Copyright © 2016 Dinh Quang Hieu. All rights reserved.
//

import UIKit
import SVProgressHUD
import GTMOAuth2

class ControllerHelper: NSObject {
    
    static var chartViewController:HDPhoneMonitorChartViewController?
    
    static func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = GoogleSheetService.scopes.joinWithSeparator(" ")
        return GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: GoogleSheetService.kClientID,
            clientSecret: nil,
            keychainItemName: GoogleSheetService.kKeychainItemName,
            delegate: self,
            finishedSelector: #selector(ControllerHelper.viewController(_:finishedWithAuth:error:))
        )
    }
    
    // Handle completion of the authorization process, and update the Google Sheets API with the new credentials.
    static func viewController(vc : UIViewController,
                               finishedWithAuth authResult : GTMOAuth2Authentication, error : NSError?) {
        
        if let error = error {
            GoogleSheetService.sharedService.authorizer = nil
            showErrorDialog(error.localizedDescription)
            return
        }
        
        GoogleSheetService.sharedService.authorizer = authResult
        vc.dismissViewControllerAnimated(true) {
            chartViewController?.sync()
        }
    }
    
    static func showErrorDialog(text: String) {
        SVProgressHUD.showErrorWithStatus(text)
    }
    
    static func showProgressDialog(text: String?, viewcontroller vc:UIViewController) {
        if text != nil {
            SVProgressHUD.showWithStatus(text)
        }
        else {
            SVProgressHUD.show()
        }
        vc.navigationItem.rightBarButtonItem?.enabled = false
        vc.navigationItem.leftBarButtonItem?.enabled = false
    }
    
    static func handleError(error: NSError, viewcontroller vc:UIViewController) {
        if let errorJSON = error.userInfo["json"] {
            
            let errorDescription = errorJSON["error_description"] as! String
            
            if errorDescription == "Token has been revoked." {
                SVProgressHUD.dismiss()
                ControllerHelper.chartViewController = vc as? HDPhoneMonitorChartViewController
                vc.presentViewController(
                    createAuthController(),
                    animated: true,
                    completion: nil
                )
            }
        }
        else if let errorDescription = error.userInfo["error"] {
            let errorDescriptionString = errorDescription as! String
            if errorDescriptionString == "Requested entity was not found." {
                GoogleSheetService.spreadsheetId = nil
                let chartViewController = vc as! HDPhoneMonitorChartViewController
                chartViewController.userDefault.setValue(nil, forKey: "spreadsheetId")
                chartViewController.userDefault.synchronize()
                chartViewController.sync()
            }
        }
        else {
            showErrorDialog(error.localizedDescription)
        }
    }
}
