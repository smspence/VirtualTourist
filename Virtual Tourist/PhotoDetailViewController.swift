//
//  PhotoDetailViewController.swift
//  Virtual Tourist
//
//  Created by Shawn Spencer on 9/9/15.
//  Copyright (c) 2015 Shawn Spencer. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    var photo: Photo? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let photo = photo,
            let image = photo.image {

                imageView.image = image
        }
    }

}
