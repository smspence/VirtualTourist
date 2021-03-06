//
//  PhotoAlbumCell.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/7/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import UIKit

class PhotoAlbumCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectionOverlayView: UIView!

    var taskToCancelifCellIsReused: NSURLSessionTask? {

        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }

    func setSelectionOverlayVisible(state : Bool) {
        selectionOverlayView.hidden = !state
    }

}
