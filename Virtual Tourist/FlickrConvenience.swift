//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/6/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import Foundation

/*
Shuffle as a mutating array method.
This extension will let you shuffle a mutable Array instance in place.
Example:
var numbers = [1, 2, 3, 4, 5, 6, 7, 8]
numbers.shuffleInPlace()  // e.g., numbers == [6, 1, 8, 3, 2, 4, 7, 5]
*/
extension MutableCollectionType where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }

        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}

extension FlickrClient {

    private func getJsonForPhotosAtLocation(latitude: Double, longitude: Double, completionHandler: (photoUrls: [String], success: Bool) -> Void) {

        let deltaDegrees = 0.25

        //bbox:
        //   A comma-delimited list of 4 values defining the Bounding Box of the area that will be searched.
        //   The 4 values represent the bottom-left corner of the box and the top-right corner, minimum_longitude, minimum_latitude, maximum_longitude, maximum_latitude.
        let bboxString = "\(longitude-deltaDegrees),\(latitude-deltaDegrees),\(longitude+deltaDegrees),\(latitude+deltaDegrees)"

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
            var photoUrls : [String] = [String]()

            if let error = error {
                print("getJsonForPhotos download error: \(error)")
            } else {

                if let photosDictionary = JSONResult["photos"] as? [String : AnyObject] {

                    // Determine the number of photos
                    let numPhotos : Int
                    if let totalPhotosVal = photosDictionary["total"] as? String {
                        numPhotos = (totalPhotosVal as NSString).integerValue
                    } else {
                        numPhotos = 0
                    }

                    print("Found \(numPhotos) photos")

                    if numPhotos > 0 {

                        // Get the URLs for the photos

                        if let photosArray = photosDictionary["photo"] as? [[String : AnyObject]] {

                            print("photosDictionary contains \(photosArray.count) photos")

                            // Return an array of 24 (or less if the returned list is smaller)
                            //   randomly-selected photo URLs
                            let maxPhotosToReturn = 24
                            let numPhotosToReturn = min(maxPhotosToReturn, photosArray.count)

                            let randomArrayIndices = self.getRandomIndicesWithArraySize(photosArray.count)

                            for ii in 0 ..< numPhotosToReturn {

                                let photoMetaData = photosArray[ randomArrayIndices[ii] ]

                                if let photoUrlString = photoMetaData["url_m"] as? String {

                                    photoUrls.append(photoUrlString)

                                }//unwrap url optional
                            }

                        }//unwrap photosArray optional
                    }

                    success = true

                } else {
                    print("!! Could not find \"photos\" object in JSON result !!")
                }
            }

            // call completion handler on the main thread
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler(photoUrls: photoUrls, success: success)
            }
        }

    }

    private func getRandomIndicesWithArraySize(let arraySize: Int) -> [Int] {

        var arrayOfIndices : [Int] = [Int]()
        arrayOfIndices.reserveCapacity(arraySize)

        for ii in 0 ..< arraySize {
            arrayOfIndices.append(ii)
        }

        arrayOfIndices.shuffleInPlace()

        return arrayOfIndices
    }

    func getPhotosAtLocation(latitude: Double, longitude: Double, completionHandler: (photoUrls: [String]) -> Void) {

        getJsonForPhotosAtLocation(latitude, longitude: longitude) { (photoUrls: [String], success: Bool) in

            if success {
                print("Successfully completed getPhotosAtLocation")
            } else {
                print("Unsuccessful getPhotosAtLocation :(")
            }

            completionHandler(photoUrls: photoUrls)
        }
    }

}
