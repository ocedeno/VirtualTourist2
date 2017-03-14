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
    var pin: PinAnnotation?
    var photoURLs: [String:Date]?
    let utility = Utility()
    
    fileprivate var selectedPhotos:[IndexPath]?
    fileprivate var isFetching = false
    //    fileprivate var photosFilePath: String
    //    {
    //        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    //    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noPhotosLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        mapView.isUserInteractionEnabled = false
        //photoCollectionView.backgroundColor = UIColor.white
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        photoCollectionView.allowsMultipleSelection = true
        
        //set Region
        if let pin = self.pin
        {
            let latitude = pin.latitude
            let longitude = pin.longitude
            let centerCoordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
            let region = MKCoordinateRegion(center: centerCoordinates, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            
            mapView.setRegion(region, animated: true)
            
            let pinMarker = MKPointAnnotation()
            pinMarker.coordinate = centerCoordinates
            mapView.addAnnotation(pinMarker)
        }
        
        loadFetchedResultsController()
        selectedPhotos = [IndexPath]()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        noPhotosLabel.isHidden = true
        
        if (pin?.photos?.count)! <= 0 {
            newCollectionButton.isEnabled = false
            getPhotos()
        }
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval)
    {
        if let pin = pin
        {
            let latitude = pin.latitude as CLLocationDegrees
            let longitude = pin.longitude as CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            mapView.setRegion(region, animated: true)
        }
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        
        let width = view.frame.width / 4
        let layout = photoCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width + 1, height: width + 1)
        
    }
    
    //MARK: - Shared Context
    lazy var sharedContext: NSManagedObjectContext =
        {
            CoreDataStack.sharedInstance.managedObjectContext
    }()
    
    //MARK: NSFetchedResultsController
    lazy var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult> =
        {
            //create the fetch request
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            
            //add a sort descriptor, enforces a sort order on the results
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
            
            //add a predicate to only get photos for the specified pin
            if let latitude = self.pin?.latitude, let longitude = self.pin?.longitude {
                let latitude = latitude as NSNumber
                let longitude = longitude as NSNumber
                let predicate = NSPredicate(format: "(pin.latitude == %@) AND (pin.longitude == %@)", latitude, longitude)
                fetchRequest.predicate = predicate
            }
            
            //create fetched results controller
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
            
            return fetchedResultsController
            
    }()
    
    func loadFetchedResultsController()
    {
        fetchedResultsController.delegate = self
        
        //get results from the fetchedResultsController
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
            self.utility.createAlert(withTitle: "Failed Query", message: "Failed to load photos", sender: self as UIViewController)
        }
    }
    
    func removePhotosFromPin(_ indexPath:IndexPath)
    {
        handleManagedObjectContextOperations
            { () -> Void in
                let photo = self.fetchedResultsController.object(at: indexPath) as! Photo
                self.sharedContext.delete(photo)
                CoreDataStack.sharedInstance.saveMainContext()
        }
    }
    
    @IBAction func newCollectionSelected(_ sender: UIBarButtonItem)
    {
        if (selectedPhotos?.count)! > 0
        {
            photoCollectionView.performBatchUpdates(
                { () -> Void in
                    for indexPath in (self.selectedPhotos?.sorted(by: { $0.item > $1.item}))!
                    {
                        self.removePhotosFromPin(indexPath)
                    }
                    
            }, completion: { (completed) -> Void in
                performUIUpdatesOnMain({ () -> Void in
                    self.photoCollectionView.deleteItems(at: self.selectedPhotos!)
                    self.selectedPhotos?.removeAll()
                    self.newCollectionButton.title = "New Collection"
                })
            })
        } else
        {
            newCollectionButton.isEnabled = false
            
            photoCollectionView.performBatchUpdates(
                { () -> Void in
                    if let pin = self.pin, let _ = pin.photos
                    {
                        self.isFetching = true
                        for photo in self.fetchedResultsController.fetchedObjects as! [Photo]
                        {
                            self.sharedContext.delete(photo)
                        }
                        
                        CoreDataStack.sharedInstance.saveMainContext()
                        
                    }
            }, completion:
                { (completed) -> Void in
                    self.isFetching = false
                    self.getPhotos()
            })
        }
    }
    
    //MARK: - Get Photos from Flickr
    func getPhotos(fromCache cache:Bool = false)
    {
        FlickrClient.sharedClient.getPhotosByLocation(using: pin!)
        { (result, error) -> Void in
            
            guard error == nil else
            {
                self.utility.createAlert(withTitle: "Failed Query", message: "Could not retrieve images for this pin location", sender: self as UIViewController)
                return
            }
            
            if let photos = result {
                if let photosDict = photos["photos"] as? [String:AnyObject]
                {
                    if let photosDesc = photosDict["photo"] as? [[String:AnyObject]]
                    {
                        print("\(photosDesc)")
                        self.photoURLs = [String:Date]()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                        for (_, photoItem) in photosDesc.enumerated()
                        {
                            if let photoURL = photoItem["url_m"] as? String, let dateTaken = photoItem["datetaken"] as? String
                            {
                                //photo urls of images to be downloaded
                                self.photoURLs![photoURL] = dateFormatter.date(from: dateTaken)
                            }
                        }
                        
                        if self.photoURLs!.keys.count > 0
                        {
                            handleManagedObjectContextOperations({ () -> Void in
                                for urlString in self.photoURLs!.keys
                                {
                                    let photo = Photo(context: self.sharedContext)
                                    let url = URL(string: urlString)
                                    photo.imageData = NSData(contentsOf: url!)
                                    photo.dateCreated = self.photoURLs![urlString]! as NSDate?
                                    photo.pin = self.pin!
                                    CoreDataStack.sharedInstance.saveMainContext()
                                }
                                
                                //performUIUpdatesOnMain({ () -> Void in
                                self.photoCollectionView.isHidden = false
                                self.newCollectionButton.isEnabled = true
                                
                            })
                            
                        } else {
                            performUIUpdatesOnMain({ () -> Void in
                                self.photoCollectionView.isHidden = true
                                self.newCollectionButton.isEnabled = true
                                self.noPhotosLabel.isHidden = false
                                
                            })
                        }
                    }
                }
            }
        }
    }
    
}

extension PhotoViewController : UICollectionViewDelegate
{
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell
        {
            cell.isSelected = true
            selectedPhotos?.append(indexPath)
            newCollectionButton.title = "Remove Selected Pictures"
            let _ = configure(cell, forRowAtIndexPath: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
    {
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell
        {
            cell.isSelected = false
            if let indexToRemove = selectedPhotos?.index(of: indexPath)
            {
                selectedPhotos?.remove(at: indexToRemove)
            }
            
            if selectedPhotos?.count == 0
            {
                newCollectionButton.title = "New Collection"
            }
            
            let _ = configure(cell, forRowAtIndexPath: indexPath)
        }
    }
}

extension PhotoViewController : UICollectionViewDataSource
{
    func configure(_ cell: PhotoCollectionViewCell, forRowAtIndexPath indexPath: IndexPath) -> UICollectionViewCell
    {
        if let indexSet = selectedPhotos
        {
            if indexSet.contains(indexPath)
            {
                if cell.photoCellImageView.alpha == 1.0
                {
                    performUIUpdatesOnMain({ () -> Void in
                        cell.photoCellImageView.alpha = 0.5
                    })
                }
            } else
            {
                performUIUpdatesOnMain({ () -> Void in
                    cell.photoCellImageView.alpha = 1.0
                })
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if let sectionInfo = fetchedResultsController.sections
        {
            return sectionInfo[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
        
        let photo = fetchedResultsController.object(at: indexPath) as! Photo
                
        if let _ = photo.imageData
        {
            cell.photoCellImageView.image = UIImage(data: photo.imageData as! Data)
            cell.photoCellLoadingView.isHidden = true
        }
        else
        {
            //if the file does not exist download it from the Internet and save it
            performDownloadsAndUpdateInBackground({ () -> Void in
                
                performUIUpdatesOnMain({ () -> Void in
                    self.getPhotos()
                    cell.photoCellImageView.image = UIImage(data: photo.imageData as! Data)
                    cell.photoCellLoadingView.isHidden = true
                })
            })
        }
        
        return configure(cell, forRowAtIndexPath: indexPath)
    }
}

extension PhotoViewController : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            if isFetching {
                photoCollectionView.reloadData()
            }
            break
            
        case .insert:
            photoCollectionView.reloadData()
            break
            
        default:
            return
        }
    }
}
