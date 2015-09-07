//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/6/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import Foundation

extension FlickrClient {

    private func getJsonForPhotosAtLocation(latitude: Double, longitude: Double, completionHandler: (success: Bool) -> Void) {

        let delta = 0.5

        //bbox:
        //   A comma-delimited list of 4 values defining the Bounding Box of the area that will be searched.
        //   The 4 values represent the bottom-left corner of the box and the top-right corner, minimum_longitude, minimum_latitude, maximum_longitude, maximum_latitude.
        let bboxString = "\(longitude-delta),\(latitude-delta),\(longitude+delta),\(latitude+delta)"

        let parameters = [
            "method": Constants.Method,
            "api_key": Constants.ApiKey,
            "extras": "url_m",
            "safe_search": "3", // 1 = safe, 2 = moderate, 3 = restricted (un-authed calls only see safe results)
            "format": "json",
            "nojsoncallback": "1",
            "bbox": bboxString
        ]

        taskForGetJson(parameters) { (JSONResult, error) in

            var success = false

            if let error = error {
                println("getJsonForPhotos download error: \(error)")
            } else {


                if let photosDictionary = JSONResult["photos"] as? [String : AnyObject] {

                    // Determine the number of photos
                    let numPhotos : Int
                    if let totalPhotosVal = photosDictionary["total"] as? String {
                        numPhotos = (totalPhotosVal as NSString).integerValue
                    } else {
                        numPhotos = 0
                    }

                    println("Found \(numPhotos) photos")

                    if numPhotos > 0 {

                        // Get the URLs for the photos

                        if let photosArray = photosDictionary["photo"] as? [[String : AnyObject]] {

                            let randomArrayIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                            let photoMetaData = photosArray[randomArrayIndex]

                            if let photoTitleString = photoMetaData["title"] as? String,
                                let photoUrlString = photoMetaData["url_m"] as? String {

                                    if let imageData = NSData(contentsOfURL: NSURL(string: photoUrlString)!) {

                                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                            // do our updates on the main thread
                                            // make these updates minimal

                                            //someUIImageView.image = UIImage(data: imageData)
                                        })
                                    } else {
                                        println("Could not download image at url: \(photoUrlString)")
                                    }
                            }//unwrap title and url optionals
                            
                        }//unwrap photosArray optional

                        success = true
                    }
                } else {
                    println("!! Could not find \"photos\" object in JSON result !!")
                }

                // call completion handler on the main thread
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(success: success)
                }
            }
        
        }

    }

    func getPhotosAtLocation(latitude: Double, longitude: Double) {

        // Dallas:
        // lat, lon: (32.7637368149042, -96.7277308320317)

        getJsonForPhotosAtLocation(latitude, longitude: longitude) { (success: Bool) in

            if success {
                println("Successfully completed getPhotosAtLocation")
            } else {
                println("Unsuccessful getPhotosAtLocation :(")
            }
        }
    }

}
