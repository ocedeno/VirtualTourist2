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
    var passedPinAnnotation: PinAnnotation?
    let utility = Utility()
    let flickrClient = FlickrClient()
    
    fileprivate var selectedPhotos:[IndexPath]?
    fileprivate var isFetching = false
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noPhotosLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        mapView.isUserInteractionEnabled = false
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        photoCollectionView.allowsMultipleSelection = true
        
        //set Region
        if let pin = self.passedPinAnnotation
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
        if passedPinAnnotation?.photos?.count ?? 0 <= 0 {
            newCollectionButton.isEnabled = false
            getPhotos()
        }
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval)
    {
        if let pin = passedPinAnnotation
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
        
        let width = view.frame.width / 3.2
        let layout = photoCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width + 1, height: width + 1)
        
    }
    
    //MARK: - Shared Context
    lazy var sharedContext: NSManagedObjectContext =
        {
            CoreDataStack.sharedInstance.mainContext
    }()
    
    //MARK: NSFetchedResultsController
    lazy var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult> =
        {
            //create the fetch request
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            
            //add a sort descriptor, enforces a sort order on the results
            fetchRequest.sortDescriptors = []
            
            //add a predicate to only get photos for the specified pin
            if let latitude = self.passedPinAnnotation?.latitude, let longitude = self.passedPinAnnotation?.longitude {
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
        background
            { () -> Void in
                let photo = self.fetchedResultsController.object(at: indexPath) as! Photo
                self.sharedContext.delete(photo)
                performUIUpdatesOnMain({ 
                    try! self.sharedContext.save()
                })
        }
    }
    
    @IBAction func newCollectionSelected(_ sender: UIBarButtonItem)
    {
        if sender.title == "Remove Selected Pictures"
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
                    print("Completion Handler of the New Collection Button if statement")
                })
            })
        } else
        {
            newCollectionButton.isEnabled = false
            photoCollectionView.performBatchUpdates(
                { () -> Void in
                    if let pin = self.passedPinAnnotation, let _ = pin.photos
                    {
                        self.isFetching = true
                        for photo in self.fetchedResultsController.fetchedObjects as! [Photo]
                        {
                            self.sharedContext.delete(photo)
                        }
                        
                        performUIUpdatesOnMain({
                            try! self.sharedContext.save()
                        })
                    }
            }, completion: { (completed) -> Void in
                print("\n2 - Above Completion Handler in Else")
                    self.getPhotos()
            })
        }
    }
    
    //MARK: - Get Photos from Flickr
    func getPhotos(fromCache cache:Bool = false)
    {
        self.flickrClient.getPhotosByLocation(using: passedPinAnnotation!, completionHandler:
        { (result, error) in
            guard error == nil else
            {
                self.utility.createAlert(withTitle: "Failed Query", message: "Could not retrieve images for this pin location", sender: self as UIViewController)
                return
            }
            
            if let photos = result
            {
                if let photosDict = photos["photos"] as? [String:AnyObject]
                {
                    if let photoArray = photosDict["photo"] as? [[String:AnyObject]]
                    {
                        for item in photoArray
                        {
                            if let photoURL = item["url_m"]
                            {
                                DispatchQueue.main.async
                                {
                                    let photoEntity = Photo(context: self.sharedContext)
                                    photoEntity.mURL = photoURL as? String
                                    photoEntity.pin = self.passedPinAnnotation
                                    self.passedPinAnnotation?.photos?.adding(photoEntity)
                                    self.loadFetchedResultsController()
                                }
                            }
                        }
                        
                        if (photoArray.count) > 0
                        {
                            performUIUpdatesOnMain({ () -> Void in
                                self.photoCollectionView.isHidden = false
                                self.newCollectionButton.isEnabled = true
                                self.photoCollectionView.reloadData()
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
        })
        try! self.sharedContext.save()
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
        return (fetchedResultsController.fetchedObjects?.count)!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
        
        loadFetchedResultsController()
        let photo = fetchedResultsController.object(at: indexPath) as! Photo
        
        if photo.imageData == nil
        {
            cell.photoCellImageView.downloadedFrom(link: photo.mURL!)
            DispatchQueue.main.async {
                //cell.photoCellLoadingView.isHidden = true
            }
            try! self.sharedContext.save()
        }
        else
        {
            //if the file does not exist download it from the Internet and save it
            cell.photoCellImageView.downloadedFrom(link: photo.mURL!)
            performUIUpdatesOnMain({ () -> Void in
                cell.photoCellLoadingView.isHidden = true
            })
        }
        
        return configure(cell, forRowAtIndexPath: indexPath)
    }
}

extension PhotoViewController : NSFetchedResultsControllerDelegate
{
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

extension UIImageView
{
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFill) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
            }.resume()
    }
    
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFill) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
