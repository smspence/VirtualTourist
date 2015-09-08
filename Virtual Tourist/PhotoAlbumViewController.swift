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

                println("photoUrls contains \(photoUrls.count) urls")
                // TODO - remove
                for url in photoUrls {
                    println(url)

                    var photo = Photo(flickrUrl: url, context: self.sharedContext)

                    photo.pin = self.pin
                }

                CoreDataStackManager.sharedInstance().saveContext()

            }

        }
    }

//    if let imageData = NSData(contentsOfURL: NSURL(string: photoUrlString)!) {
//
//        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//            // do our updates on the main thread
//            // make these updates minimal
//
//            //someUIImageView.image = UIImage(data: imageData)
//        })
//    } else {
//        println("Could not download image at url: \(photoUrlString)")
//    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoAlbumCellReuseId", forIndexPath: indexPath) as! PhotoAlbumCell
//        let meme = memes[indexPath.item]
//        cell.imageView.image = meme.memedImage
//
//        if self.selectedIndexPaths.contains(indexPath) {
//            cell.setSelectionOverlayVisible(true)
//        } else {
//            cell.setSelectionOverlayVisible(false)
//        }

        return cell
    }

}
