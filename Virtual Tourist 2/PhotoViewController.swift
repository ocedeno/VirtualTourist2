//
//  PhotoViewController.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/9/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController
{
    var pin: PinAnnotation!
    var photoURLs: [String:Date]?
    
    fileprivate var selectedPhotos:[IndexPath]?
    fileprivate var isFetchingData = false
    fileprivate var photosFilePath: String
    {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noPhotosLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        
    }
}
