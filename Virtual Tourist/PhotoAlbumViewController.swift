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

    var pin: Pin!

    @IBOutlet weak var noImagesLabel: UILabel!

    var downloadsInProgress: Int = 0 {
        didSet {
            // The newCollectionButton should only be enabled
            //  if there are currently no photos in the process of being downloaded
            if downloadsInProgress == 0 {
                newCollectionButton.enabled = true
            } else {
                newCollectionButton.enabled = false
            }
        }
    }

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self

        noImagesLabel.hidden = true

        setUpMapView()

        if pin.photos.count > 0 {
            println("pin already has \(pin.photos.count) photos")
        }

        if pin.photos.isEmpty {
            downloadPhotoUrls()
        }
    }

    func downloadPhotoUrls() {

        FlickrClient.sharedInstance().getPhotosAtLocation(pin.location.latitude, longitude: pin.location.longitude) { (photoUrls: [String]) in

            self.noImagesLabel.hidden = (photoUrls.count > 0)

            for url in photoUrls {

                var photo = Photo(flickrUrl: url, context: self.sharedContext)

                // Establish the relationship between photo and pin in CoreData
                photo.pin = self.pin
            }

            CoreDataStackManager.sharedInstance().saveContext()

            self.collectionView.reloadData()
        }
    }

    func setUpMapView() {
        let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = pin.location
        mapView.addAnnotation(newAnnotation)
        mapView.setRegion(MKCoordinateRegion(center: pin.location, span: MKCoordinateSpan(latitudeDelta: 0.075, longitudeDelta: 0.075)), animated: false)
    }

    @IBAction func handleNewCollectionButtonTapped(sender: AnyObject) {
        println("newCollectionButton tapped")

        pin.clearPhotos()

        self.collectionView.reloadData()

        downloadPhotoUrls()
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pin.photos.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoAlbumCellReuseId", forIndexPath: indexPath) as! PhotoAlbumCell

        var image = UIImage(named: "photoPlaceholder")

        let photo = pin.photos[indexPath.item]

        if photo.flickrUrl == nil || photo.flickrUrl == "" {
            println("!! Photo has no Flickr URL, cannot download !!")
        } else if photo.image != nil {
            image = photo.image
        } else {

            // The image needs to be downloaded from Flickr

            downloadsInProgress++

            let task = FlickrClient.sharedInstance().taskForFile(photo.flickrUrl!) { (downloadedData, error) -> Void in

                dispatch_async(dispatch_get_main_queue()) {
                    downloadsInProgress--
                }

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

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let photo = pin.photos[indexPath.item]

        let photoDetailVC = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoDetailViewControllerId") as! PhotoDetailViewController
        photoDetailVC.photo = photo
        self.navigationController!.pushViewController(photoDetailVC, animated: true)
    }

}
