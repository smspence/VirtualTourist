//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/6/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import MapKit
import CoreData

@objc(Pin)

class Pin : NSManagedObject {

    struct Constants {
        static let EntityName = "Pin"
    }

    @NSManaged private var latitudeDegrees : Double
    @NSManaged private var longitudeDegrees : Double
    @NSManaged var photos : [Photo]

    // Standard CoreData init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(latLonLocation: CLLocationCoordinate2D, context: NSManagedObjectContext) {

        let entity =  NSEntityDescription.entityForName(Pin.Constants.EntityName, inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)

        self.latitudeDegrees = latLonLocation.latitude
        self.longitudeDegrees = latLonLocation.longitude
    }

    var location : CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.latitudeDegrees, longitude: self.longitudeDegrees)
        }

        set {
            self.latitudeDegrees = newValue.latitude
            self.longitudeDegrees = newValue.longitude
        }
    }

    func clearPhotos() {

        for photo in self.photos {
            photo.image = nil //This deletes the image file from the image cache and from the documents directory
            CoreDataStackManager.sharedInstance().managedObjectContext!.deleteObject(photo) //This removes the photo object from CoreData
        }

        CoreDataStackManager.sharedInstance().saveContext()
    }

}
