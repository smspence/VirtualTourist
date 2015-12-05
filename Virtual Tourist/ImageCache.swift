//
//  ImageCache.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/7/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import UIKit

class ImageCache {

    private var inMemoryCache = NSCache()

    // MARK: - Retreiving images

    func imageWithIdentifier(identifier: String?) -> UIImage? {

        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {

            print("!! In imageWithIdentifier, identifier is nil or empty !!")

            return nil
        }

        let path = pathForIdentifier(identifier!)

        // First try the memory cache
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            print("Returned image from inMemoryCache")
            return image
        }

        // Next Try the hard drive
        if let data = NSData(contentsOfFile: path) {
            print("Returned image from hard drive")

            let image = UIImage(data: data)
            // Save the image in the cache before returning,
            //  so it can be quickly fetched later if needed
            inMemoryCache.setObject(image!, forKey: path)

            return image
        }

        print("Reached the end of imageWithIdentifier.")

        return nil
    }

    // MARK: - Saving images

    func storeImage(image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)

        // If the image is nil, remove images from the cache
        if image == nil {

            print("Setting to nil in ImageCache, deleting image file")

            inMemoryCache.removeObjectForKey(path)
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch _ {
            }
            return
        }

        // Otherwise, keep the image in memory
        inMemoryCache.setObject(image!, forKey: path)

        // And in documents directory
        let data = UIImagePNGRepresentation(image!)
        data!.writeToFile(path, atomically: true)
    }

    // MARK: - Helper

    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)

        return fullURL.path!
    }
}
