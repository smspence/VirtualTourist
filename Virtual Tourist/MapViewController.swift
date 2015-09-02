//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/1/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import UIKit
import MapKit

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

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        restoreMapRegion(false)
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
}
