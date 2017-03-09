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

class MapViewController: UIViewController, MKMapViewDelegate
{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var mapSettings =  [String:AnyObject]()
    var deleteButton: UIButton!
    var isMapEditing = false
    var buttonHeight: CGFloat = 0.0
    var currentPin: PinAnnotation?
    
    var mapSettingPath: String
        {
            let manager = FileManager.default
            let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
            return url.appendingPathComponent("mapset").path
        }
    
    //percentage of height for delete button in any orientation
    var buttonHeightConstant:CGFloat = 0.096
    
    @IBAction func editButtonSelected(_ sender: UIBarButtonItem)
    {
        isMapEditing = !isMapEditing
        
        if isMapEditing
        {
            editButton.title = "Done"
            alterMapHeight(true)
        }else
        {
            editButton.title = "Edit"
            alterMapHeight(false)
        }
    }
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        mapView.delegate = self
        setupDeleteButton()
    }
    
    func alterMapHeight(_ buttonVisible: Bool)
    {
        buttonHeight = buttonHeightConstant * view.bounds.maxY
        
        if buttonVisible {
            deleteButton.isHidden = !buttonVisible
            
            UIView.animate(withDuration: 0.7, animations: { () -> Void in
                self.mapView.frame.origin.y -= self.buttonHeight
                self.deleteButton.frame.origin.y -=  self.buttonHeight
            })
            
        } else {
            UIView.animate(withDuration: 0.7, animations: { () -> Void in
                self.mapView.frame.origin.y = 0
                self.deleteButton.frame.origin.y = self.view.bounds.maxY
            }, completion: { (complete) -> Void in
                self.deleteButton.isHidden = !buttonVisible
            })
        }
    }
    
    func setupDeleteButton() {
        deleteButton = UIButton()
        deleteButton.isHidden = true
        buttonHeight = buttonHeightConstant * view.bounds.maxY
        deleteButton.frame = CGRect(x: 0, y: view.bounds.maxY, width: view.bounds.size.width, height: buttonHeightConstant * view.bounds.maxY)
        deleteButton.backgroundColor = UIColor.red
        deleteButton.setTitle("Tap Pins to Delete!", for: UIControlState())
        
        view.addSubview(deleteButton)
    }
}
