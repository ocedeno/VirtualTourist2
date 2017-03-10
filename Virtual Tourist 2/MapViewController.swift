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
    var deleteButton: UIButton!
    var isMapEditing = false
    var buttonHeight: CGFloat = 0.0
    var currentPin: MyPinAnnotation?
    
    //MARK: - Shared Context
    lazy var sharedContext: NSManagedObjectContext =
        {
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
        
        reloadPinsToMapView()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        //reposition map region and span
        if let settingsDict = NSKeyedUnarchiver.unarchiveObject(withFile: mapSettingPath) as? [String:AnyObject]
        {
            let latitude = settingsDict["latitude"] as! CLLocationDegrees
            let longitude = settingsDict["longitude"] as! CLLocationDegrees
            let mapCenter = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            mapView.centerCoordinate = mapCenter
            
            let latDelta = (settingsDict["latitudeDelta"] as! CLLocationDegrees)
            let longDelta = (settingsDict["longitudeDelta"] as! CLLocationDegrees)
            let mapSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
            
            mapView.region.span = mapSpan
        }
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
    
    func createAlert(withTitle title:String, message:String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval)
    {
        buttonHeight = buttonHeightConstant * view.bounds.maxY
        let buttonOriginY = (deleteButton.isHidden) ? view.bounds.maxY : view.bounds.maxY - buttonHeight
        deleteButton.frame = CGRect(x: 0, y: buttonOriginY, width: view.bounds.size.width, height: buttonHeight)
    }
    
    func setupDeleteButton()
    {
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
                    pinEntity.latitude = (Float(pin.coordinate.latitude) as NSNumber?)!
                    pinEntity.longitude = (Float(pin.coordinate.longitude) as NSNumber?)!
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
    
    func reloadPinsToMapView()
    {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PinAnnotation")
        
        do
        {
            if let results = try CoreDataStack.sharedInstance.managedObjectContext.fetch(fetchRequest) as? [PinAnnotation]
            {
                for mapPin in results
                {
                    let pin = MyPinAnnotation()
                    let latitude = mapPin.latitude
                    let longitude = mapPin.longitude
                    pin.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
                    
                    pin.pin = mapPin
                    mapView.addAnnotation(pin)
                }
            }
        }catch
        {
            createAlert(withTitle: "Query Error", message: "There was an error retrieving the pins from the database!")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "getPhotosSegue" {
            let destination = segue.destination as! PhotoViewController
            let annotation = sender as! MyPinAnnotation
            
            if let pin = annotation.pin {
                destination.pin = pin
                mapView.deselectAnnotation(annotation, animated: true)
            }
        }
    }

}

extension MapViewController : MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        //capture the map settings after the map region has changed
        mapSettings["latitudeDelta"] = mapView.region.span.latitudeDelta as AnyObject?
        mapSettings["longitudeDelta"] = mapView.region.span.longitudeDelta as AnyObject?
        mapSettings["latitude"] = mapView.centerCoordinate.latitude as AnyObject?
        mapSettings["longitude"] = mapView.centerCoordinate.longitude as AnyObject?
        
        NSKeyedArchiver.archiveRootObject(mapSettings, toFile: mapSettingPath)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
        pinView.animatesDrop = true
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        if isMapEditing
        {
            //delete annotation
            if let annotation = view.annotation as? MyPinAnnotation
            {
                if let pin = annotation.pin
                {
                    sharedContext.delete(pin)
                    
                    //save the context
                    CoreDataStack.sharedInstance.saveMainContext()
                    
                    
                    mapView.removeAnnotation(annotation)
                }
            }
        }else
        {
            //get images for pin location
            if let annotation = view.annotation as? MyPinAnnotation
            {
                if let _ = annotation.pin
                {
                    performSegue(withIdentifier: "getPhotosSegue", sender: annotation)
                }
            }
        }
    }
}
