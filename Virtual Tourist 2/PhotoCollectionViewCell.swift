//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/9/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var photoCellImageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var photoCellLoadingView: UIView!
        {
        didSet
        {
            photoCellLoadingView.clipsToBounds = true
            photoCellLoadingView.layer.cornerRadius = 10
            photoCellLoadingView.addSubview(activityIndicatorView)
            activityIndicatorView.hidesWhenStopped = true
            activityIndicatorView.activityIndicatorViewStyle = .whiteLarge
            activityIndicatorView.startAnimating()
            
        }
    }
}
