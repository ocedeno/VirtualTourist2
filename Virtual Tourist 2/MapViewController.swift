//
//  MapViewController.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/9/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController
{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var mapSettings =  [String:AnyObject]()
    var deleteButton:UIButton!
    var isMapEditing = false
    var buttonHeight:CGFloat = 0.0
    var currentPin:PinAnnotation?
    
    var mapSettingPath: String
        {
            let manager = FileManager.default
            let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
            return url.appendingPathComponent("mapset").path
        }
    
    //percentage of height for delete button in any orientation
    var buttonHeightConstant:CGFloat = 0.096
    
    @IBOutlet weak var editButtonSelected: UIBarButtonItem!
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
}
