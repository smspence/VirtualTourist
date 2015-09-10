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

    var editButton: UIBarButtonItem!
    var editModeEnabled = false
    var selectedIndexPaths = Set<NSIndexPath>()

    @IBOutlet weak var trashButton: UIBarButtonItem!
    @IBOutlet weak var toolbarWithTrashButton: UIToolbar!

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
    @IBOutlet weak var toolbarWithNewCollectionButton: UIToolbar!

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.allowsMultipleSelection = true

        noImagesLabel.hidden = true

        setUpMapView()

        toolbarWithNewCollectionButton.hidden = false
        toolbarWithTrashButton.hidden = true

        addRightBarButtonItem()

        if pin.photos.count > 0 {
            println("pin already has \(pin.photos.count) photos")
        }

        if pin.photos.isEmpty {
            downloadPhotoUrls()
        }
    }

    func addRightBarButtonItem() {
        editButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Plain, target: self, action: "editButtonTapped:")
        self.navigationItem.setRightBarButtonItem(editButton, animated: false)
    }

    func editButtonTapped(sender: AnyObject) {

        editModeEnabled = !editModeEnabled

        if editModeEnabled {
            // "Edit" was pressed
            editModeStart()
        } else {
            // "Cancel" was pressed
            editModeEnd()
        }
    }

    func editModeStart() {

        editButton.title = "Cancel"

        toolbarWithNewCollectionButton.hidden = true
        toolbarWithTrashButton.hidden = false
        trashButton.enabled = false
    }

    func editModeEnd() {
        // User has either cancelled editing,
        //  or confirmed deletion, so set things back
        //  to how they were before Edit was tapped

        //  Make sure the previously selected photos are all deselected
        for indexPath in selectedIndexPaths {
            collectionView.deselectItemAtIndexPath(indexPath, animated: false)

            if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? PhotoAlbumCell {
                cell.setSelectionOverlayVisible(false)
            }
        }

        selectedIndexPaths.removeAll(keepCapacity: false)

        editButton.title = "Edit"

        toolbarWithNewCollectionButton.hidden = false
        toolbarWithTrashButton.hidden = true
        trashButton.enabled = false

        editModeEnabled = false
    }

    func updateModelAndDeleteItemsFromCollectionView(collectionView: UICollectionView, indexPathsToDelete: [NSIndexPath]) {

        for indexPath in indexPathsToDelete {

            var photo = pin.photos[indexPath.item]
            photo.image = nil //This deletes the image file from the image cache and from the documents directory
            CoreDataStackManager.sharedInstance().managedObjectContext!.deleteObject(photo) //This removes the photo object from CoreData
        }

        CoreDataStackManager.sharedInstance().saveContext()

        collectionView.deleteItemsAtIndexPaths(indexPathsToDelete)
    }

    func doDelete() {

        // When deleting multiple photos at once,
        //    we have to delete items from the photos array in order from
        //    highest to lowest index, to prevent attempts to delete
        //    an index that is out of range.
        // Create an array with the contents of our selectedIndexPaths set.
        // Sort the array from highest to lowest item index.
        var sortedArray = Array(self.selectedIndexPaths)
        sortedArray.sort { (indexPath1 : NSIndexPath, indexPath2 : NSIndexPath) -> Bool in
            return indexPath1.item > indexPath2.item
        }

        updateModelAndDeleteItemsFromCollectionView(collectionView, indexPathsToDelete: sortedArray)

        editModeEnd()
    }

    @IBAction func handleTrashButtonTapped(sender: AnyObject) {

        // Present an alert asking the user if they are sure they want to delete

        let selectedCount = selectedIndexPaths.count

        let controller = UIAlertController()
        controller.title = "Are you sure you want to delete the selected photo"
        controller.title = controller.title! + ((selectedCount > 1) ? "s?" : "?")

        let deleteButtonTitle = (selectedCount > 1) ? "Delete \(selectedCount) Photos" : "Delete Photo"
        let deleteAction = UIAlertAction(title: deleteButtonTitle, style: UIAlertActionStyle.Destructive) {
            action in self.doDelete()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
            action in self.dismissViewControllerAnimated(true, completion: nil)
        }

        controller.addAction(deleteAction)
        controller.addAction(cancelAction)
        self.presentViewController(controller, animated: true, completion: nil)
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

        if selectedIndexPaths.contains(indexPath) {
            cell.setSelectionOverlayVisible(true)
        } else {
            cell.setSelectionOverlayVisible(false)
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        if editModeEnabled {
            // Add the selected photo to the list of items that will potentially be deleted,
            //   and show the selection overlay over this item in the collection view

            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoAlbumCell

            // The cell should be selected for deletion
            cell.setSelectionOverlayVisible(true)
            selectedIndexPaths.insert(indexPath)

            trashButton.enabled = true

        } else {

            // Show the detail view for the selected photo

            collectionView.deselectItemAtIndexPath(indexPath, animated: false)

            let photo = pin.photos[indexPath.item]
            let photoDetailVC = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoDetailViewControllerId") as! PhotoDetailViewController
            photoDetailVC.photo = photo
            self.navigationController!.pushViewController(photoDetailVC, animated: true)
        }
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {

        if editModeEnabled {
            if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? PhotoAlbumCell {
                cell.setSelectionOverlayVisible(false)
            }
            selectedIndexPaths.remove(indexPath)
            trashButton.enabled = (self.selectedIndexPaths.count > 0)
        }
    }

}
