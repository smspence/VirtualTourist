//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/1/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    struct MapRegionKeys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let LatitudeDelta = "latitudeDelta"
        static let LongitudeDelta = "longitudeDelta"
    }

    var mapRegionFilePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Delegate methods defined in class extension at bottom of this file
        mapView.delegate = self

        restoreMapRegion(false)

        let restoredPins = fetchAllPins()
        if restoredPins.count > 0 {

            var annotations = [MKPointAnnotation]()

            for pin in restoredPins {
                let newAnnotation = MKPointAnnotation()
                newAnnotation.coordinate = pin.location
                annotations.append(newAnnotation)
            }

            mapView.addAnnotations(annotations)
        }

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        mapView.addGestureRecognizer(longPressRecognizer)
    }

    func fetchAllPins() -> [Pin] {
        let error: NSErrorPointer = nil

        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: Pin.Constants.EntityName)

        // Execute the Fetch Request
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)

        // Check for Errors
        if error != nil {
            println("Error in fetchAllPins(): \(error)")
        }

        // Return the results, cast to an array of Pin objects
        return results as! [Pin]
    }

    func handleLongPress(gestureRecognizer: UIGestureRecognizer) {

        if gestureRecognizer.state == .Began {

            let touchCoordinatesXY : CGPoint = gestureRecognizer.locationInView(mapView)

            let latLonCoordinates = mapView.convertPoint(touchCoordinatesXY, toCoordinateFromView: mapView)

            println("x, y: \(touchCoordinatesXY)  lat, lon: (\(latLonCoordinates.latitude), \(latLonCoordinates.longitude))")

            addMapAnnotationAtLatLon(latLonCoordinates)
            addPinObjectAtLatLon(latLonCoordinates)
        }
    }

    func addPinObjectAtLatLon(latLonPoint: CLLocationCoordinate2D) {

        // Create a new Pin object to be saved using CoreData
        let newPin = Pin(latLonLocation: latLonPoint, context: sharedContext)
        CoreDataStackManager.sharedInstance().saveContext()
    }

    func addMapAnnotationAtLatLon(latLonPoint: CLLocationCoordinate2D) {

        let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = latLonPoint

        mapView.addAnnotation(newAnnotation)
    }

    func fetchPinForAnnotation(annotation: MKPointAnnotation) -> Pin? {

        let fetchRequest = NSFetchRequest(entityName: Pin.Constants.EntityName)

        fetchRequest.predicate = NSPredicate(format: "latitudeDegrees == %lf && longitudeDegrees == %lf",
            annotation.coordinate.latitude, annotation.coordinate.longitude)

        let error: NSErrorPointer = nil
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)

        if error != nil {
            println("Error in fetchAllPins(): \(error)")
        }

        var returnObject : Pin? = nil

        if let results = results as? [Pin] {

            if results.count > 0 {

                returnObject = results[0]

                if results.count > 1 {
                    println("!! fetch for Pin for annotation returned \(results.count) results, supposed to be only 1 result !!")
                }

            } else {
                println("!! fetch for Pin for annotation returned 0 results !!")
            }
        }

        return returnObject
    }

    func saveMapRegion() {

        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.

        let dictionary = [
            MapRegionKeys.Latitude : mapView.region.center.latitude,
            MapRegionKeys.Longitude : mapView.region.center.longitude,
            MapRegionKeys.LatitudeDelta : mapView.region.span.latitudeDelta,
            MapRegionKeys.LongitudeDelta : mapView.region.span.longitudeDelta
        ]

        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: mapRegionFilePath)
    }

    func restoreMapRegion(animated: Bool) {

        // If we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(mapRegionFilePath) as? [String : AnyObject] {

            let latitude = regionDictionary[MapRegionKeys.Latitude] as! CLLocationDegrees
            let longitude = regionDictionary[MapRegionKeys.Longitude] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

            let latitudeDelta = regionDictionary[MapRegionKeys.LatitudeDelta] as! CLLocationDegrees
            let longitudeDelta = regionDictionary[MapRegionKeys.LongitudeDelta] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)

            let savedRegion = MKCoordinateRegion(center: center, span: span)

            println("Unarchived map region: lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")

            mapView.setRegion(savedRegion, animated: animated)
        }
    }

}

// This extension comforms to the MKMapViewDelegate protocol. This allows
// the view controller to be notified whenever the map region changes. So
// that it can save the new region.
extension MapViewController : MKMapViewDelegate {

    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }

    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {

        if let pin = fetchPinForAnnotation(view.annotation as! MKPointAnnotation) {

            let photoAlbumVC = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewControllerId") as! PhotoAlbumViewController

            photoAlbumVC.pin = pin

            self.navigationController!.pushViewController(photoAlbumVC, animated: true)

        } else {
            println("!! Could not find Pin object associated with annotation !!")
        }
    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {

        let reuseId = "pin"

        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinColor = .Red
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }

        return pinView
    }
}
