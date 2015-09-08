//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/6/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {

    // Shared session
    var session: NSURLSession

    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }

    struct Caches {
        static let imageCache = ImageCache()
    }

    // MARK: - Shared Instance

    class func sharedInstance() -> FlickrClient {

        struct Singleton {
            static var sharedInstance = FlickrClient()
        }

        return Singleton.sharedInstance
    }

    func taskForGetJson(parameters: [String : AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {

        /* 1. Set the parameters */
        /* 2/3. Build the URL and configure the request */
        let urlString = Constants.BaseURLSecure + WebHelper.escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)

        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in

            /* 5/6. Parse the data and use the data (happens in completion handler) */
            if downloadError != nil {
                completionHandler(result: nil, error: downloadError)
            } else {
                FlickrClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
            }
        }

        /* 7. Start the request */
        task.resume()

        return task
    }

    /* Helper: Given raw JSON, return a usable Foundation object */
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {

        var parsingError: NSError? = nil

        let parsedResult : AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)

        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }

    func taskForFile(urlString: String, completionHandler: (downloadedData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {

        let url = NSURL(string: urlString)!

        let request = NSURLRequest(URL: url)

        let task = session.dataTaskWithRequest(request) {data, response, downloadError in

            if downloadError != nil {
                completionHandler(downloadedData: nil, error: downloadError)
            } else {
                completionHandler(downloadedData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }
    
}
