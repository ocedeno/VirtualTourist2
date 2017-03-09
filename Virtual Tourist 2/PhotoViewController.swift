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
    
    //MARK: - Shared Context
    lazy var sharedContext: NSManagedObjectContext =
        {
        CoreDataStack.sharedInstance.managedObjectContext
        }()
    
    fileprivate var selectedPhotos:[IndexPath]?
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
        
        mapView.isUserInteractionEnabled = false
        photoCollectionView.backgroundColor = UIColor.white
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        photoCollectionView.allowsMultipleSelection = true
        
        //set Region
        if let pin = self.pin
        {
            let latitude = pin.latitude
            let longitude = pin.longitude
            let centerCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(center: centerCoordinates, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            
            mapView.setRegion(region, animated: true)
            
            let pinMarker = MKPointAnnotation()
            pinMarker.coordinate = centerCoordinates
            mapView.addAnnotation(pinMarker)
        }
        
        loadFetchResultsController()
        selectedPhotos = [IndexPath]()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        noPhotosLabel.isHidden = true
        
        if (pin?.photos?.count)! <= 0 {
            newCollection.isEnabled = false
            getPhotos()
        }
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval)
    {
        if let pin = pin
        {
            let latitude = pin.latitude
            let longitude = pin.longitude
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            mapView.setRegion(region, animated: true)
        }
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        
        let width = view.frame.width / 3
        let layout = photoCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width - 1, height: width - 1)
        
    }
    
    //MARK: NSFetchedResultsController
    lazy var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult> =
        {
        //create the fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        
        //add a sort descriptor, enforces a sort order on the results
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateTaken", ascending: false)]
        
        //add a predicate to only get photos for the specified pin
        if let latitude = self.pin?.latitude, let longitude = self.pin?.longitude
        {
            let predicate = NSPredicate(format: "(pin.latitude == %@) AND (pin.longitude == %@)", latitude, longitude)
            fetchRequest.predicate = predicate
        }
        
        //create fetched results controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        
        }()
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
            newCollection.setTitle("Remove Selected Pictures", for: UIControlState())
            configure(cell, forRowAtIndexPath: indexPath)
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
                newCollection.setTitle("New Collection", for: UIControlState())
            }
            
            configure(cell, forRowAtIndexPath: indexPath)
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sectionInfo = fetchedResultsController.sections {
            return sectionInfo[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
        
        let photo = fetchedResultsController.object(at: indexPath) as! Photo
        
        let imageLocation = photo.imageLocation!
        
        if FileManager.default.fileExists(atPath: URL(string: self.photosFilePath)!.appendingPathComponent(imageLocation).path) {
            cell.photoCellImageView.image = UIImage(contentsOfFile: URL(string: self.photosFilePath)!.appendingPathComponent(imageLocation).path)
            cell.loadingView.isHidden = true
        } else {
            //if the file does not exist download it from the Internet and save it
            if let imageURL = URL(string: photo.imageUrl) {
                performDownloadsAndUpdateInBackground({ () -> Void in
                    if let imageData = try? Data(contentsOf: imageURL) {
                        //save file
                        try? imageData.write(to: URL(fileURLWithPath: URL(string: self.photosFilePath)!.appendingPathComponent(imageURL.lastPathComponent).path), options: [.atomic])
                        
                        performUIUpdatesOnMain({ () -> Void in
                            cell.photoCellImageView.image = UIImage(data: imageData)
                            cell.loadingView.isHidden = true
                        })
                    }
                })
            }
        }
        
        return configure(cell, forRowAtIndexPath: indexPath)
    }
}

extension PhotoViewController : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            if isFetchingData {
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
