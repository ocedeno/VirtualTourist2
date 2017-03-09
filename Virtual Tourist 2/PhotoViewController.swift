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
        
        mapView.isUserInteractionEnabled = false
        photoCollectionView.backgroundColor = UIColor.white
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        photoCollectionView.allowsMultipleSelection = true
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoViewCell
        
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
