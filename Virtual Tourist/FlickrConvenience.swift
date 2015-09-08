//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/6/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import Foundation

extension FlickrClient {

    private func getJsonForPhotosAtLocation(latitude: Double, longitude: Double, completionHandler: (photoUrls: [String], success: Bool) -> Void) {

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

                var photoUrls : [String] = [String]()

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

                            let maxPhotosToReturn = 5
                            let numPhotosToReturn : Int

                            if maxPhotosToReturn < numPhotos {
                                numPhotosToReturn = maxPhotosToReturn
                            } else {
                                numPhotosToReturn = numPhotos
                            }

                            for ii in 0 ..< numPhotosToReturn {

                                // First photo in array
                                let photoMetaData = photosArray[ii]

                                if let photoUrlString = photoMetaData["url_m"] as? String {

                                    photoUrls.append(photoUrlString)

                                }//unwrap url optional
                            }

                        }//unwrap photosArray optional
                    }

                    success = true

                } else {
                    println("!! Could not find \"photos\" object in JSON result !!")
                }

                // call completion handler on the main thread
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(photoUrls: photoUrls, success: success)
                }
            }

        }

    }

    func getPhotosAtLocation(latitude: Double, longitude: Double, completionHandler: (photoUrls: [String]) -> Void) {

        // Dallas:
        // lat, lon: (32.7637368149042, -96.7277308320317)

        getJsonForPhotosAtLocation(latitude, longitude: longitude) { (photoUrls: [String], success: Bool) in

            if success {
                println("Successfully completed getPhotosAtLocation")
            } else {
                println("Unsuccessful getPhotosAtLocation :(")
            }

            completionHandler(photoUrls: photoUrls)
        }
    }

}
