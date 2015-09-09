//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/7/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import UIKit
import CoreData

@objc(Photo)

class Photo : NSManagedObject {

    struct Constants {
        static let EntityName = "Photo"
    }

    @NSManaged var flickrUrl : String?
    @NSManaged private var localFileName : String?
    @NSManaged var pin : Pin?

    // Standard CoreData init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(flickrUrl: String, context: NSManagedObjectContext) {

        let entity =  NSEntityDescription.entityForName(Photo.Constants.EntityName, inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)

        self.flickrUrl = flickrUrl
        self.localFileName = flickrUrl.lastPathComponent
    }

    var image: UIImage? {

        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(localFileName)
        }

        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: localFileName!)
        }
    }

}
