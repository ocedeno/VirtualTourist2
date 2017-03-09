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
    var currentPin: MyPinAnnotation?
    
    //MARK: - Shared Context
    lazy var sharedContext: NSManagedObjectContext = {
        CoreDataStack.sharedInstance.managedObjectContext
    }()
    
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
        
        //add long press gesture for pins
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addPinToMap(_:)))
        longPressGesture.minimumPressDuration = 1
        mapView.addGestureRecognizer(longPressGesture)
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
    
    //MARK: Map Functions
    func addPinToMap(_ longPressGesture:UILongPressGestureRecognizer)
    {
        if isMapEditing
        {
            return
        }
        
        switch longPressGesture.state
        {
            case .began:
                currentPin = MyPinAnnotation()
                let touchCoord = longPressGesture.location(in: mapView)
                currentPin!.coordinate = mapView.convert(touchCoord, toCoordinateFrom: mapView)
                mapView.addAnnotation(currentPin!)
                
                break
                
            case .changed:
                if let pin = currentPin
                {
                    let touchCoord = longPressGesture.location(in: mapView)
                    pin.coordinate = mapView.convert(touchCoord, toCoordinateFrom: mapView)
                }
                
                break
                
            case .ended:
                if let pin = self.currentPin
                {
                    let pinEntity = PinAnnotation(context: self.sharedContext)
                    pinEntity.latitude = pin.coordinate.latitude 
                    pinEntity.longitude = pin.coordinate.longitude
                    pin.pin = pinEntity
                    
                    //save the pin
                    CoreDataStack.sharedInstance.saveMainContext()
                    
                    //after the pin has been saved -- there is no longer a current pin
                    currentPin = nil
                }
                
                break
                
            default:
                break
        }
    }

}
