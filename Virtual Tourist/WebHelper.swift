//
//  WebHelper.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/6/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import UIKit

class WebHelper : NSObject {

    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {

        var urlVars = [String]()

        for (key, value) in parameters {

            /* Make sure that it is a string value */
            let stringValue = "\(value)"

            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())

            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]

        }

        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }

    class func showNetworkActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }

    class func hideNetworkActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    class func displayAlertMessage(message: String, viewController: UIViewController) {
        let controller = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)

        let okAction = UIAlertAction(title: "ok", style: UIAlertActionStyle.Default, handler: nil)

        controller.addAction(okAction)
        viewController.presentViewController(controller, animated: true, completion: nil)
    }
    
}
