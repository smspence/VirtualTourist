//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/7/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var pin : Pin!

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self

        if pin.photos.count > 0 {
            println("pin already has \(pin.photos.count) photos")
        }

        if pin.photos.isEmpty {

            FlickrClient.sharedInstance().getPhotosAtLocation(pin.location.latitude, longitude: pin.location.longitude) { (photoUrls: [String]) in

                for url in photoUrls {

                    var photo = Photo(flickrUrl: url, context: self.sharedContext)

                    // Establish the relationship between photo and pin in CoreData
                    photo.pin = self.pin
                }

                CoreDataStackManager.sharedInstance().saveContext()

                self.collectionView.reloadData()
            }

        }
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pin.photos.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoAlbumCellReuseId", forIndexPath: indexPath) as! PhotoAlbumCell

        var image = UIImage(named: "photoPlaceholder")

        let photo = self.pin.photos[indexPath.item]

        if photo.flickrUrl == nil || photo.flickrUrl == "" {
            println("!! Photo has no Flickr URL, cannot download !!")
        } else if photo.image != nil {
            image = photo.image
        } else {

            // The image needs to be downloaded from Flickr

            let task = FlickrClient.sharedInstance().taskForFile(photo.flickrUrl!) { (downloadedData, error) -> Void in

                if let error = error {
                    println("Error returned when trying to download image from Flickr: \(error)")
                }

                if let imageData = downloadedData {

                    let downloadedImage = UIImage(data: imageData)

                    // Make sure UI updates and CoreData updates are made on the main thread
                    dispatch_async(dispatch_get_main_queue()) {

                        cell.imageView.image = downloadedImage

                        // Make sure the image is associated with the Photo object in CoreData
                        photo.image = downloadedImage
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
            }

            cell.taskToCancelifCellIsReused = task
        }

        cell.imageView.image = image

        return cell
    }

}
