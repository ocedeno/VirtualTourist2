//
//  Photo+CoreDataClass.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/9/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//

import UIKit
import CoreData


public class Photo: NSManagedObject
{
    struct Keys
    {
        static let imageData = "imageData"
        static let dateCreated = "dateCreated"
        static let imageCoordinates = "imageCoordinates"
    }
    
    fileprivate var photosFilePath: String
        {
            return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertInto: context)
    }
    
    init(context: NSManagedObjectContext)
    {
        guard let photoEntity = NSEntityDescription.entity(forEntityName: "Photo", in: context) else
        {
            fatalError("Could not create Photo Entity Description!")
        }
        
        super.init(entity: photoEntity, insertInto: context)
    }
    
    init(dictionary: [String:AnyObject], context: NSManagedObjectContext)
    {
        guard let photoEntity = NSEntityDescription.entity(forEntityName: "Photo", in: context) else
        {
            fatalError("Could not create Photo Entity Description!")
        }
        
        super.init(entity: photoEntity, insertInto: context)
        
        imageCoordinates = dictionary[Keys.imageCoordinates] as? String
        dateCreated = dictionary[Keys.dateCreated] as! Date as NSDate?
        imageData = dictionary[Keys.imageData] as? String
    }
    
    override public func prepareForDeletion() {
        //delete photos from disk
        
        if let imageCoordinates = self.imageCoordinates {
            if FileManager.default.fileExists(atPath: URL(string: self.photosFilePath)!.appendingPathComponent(imageCoordinates).path) {
                do {
                    try FileManager.default.removeItem(atPath: URL(string: self.photosFilePath)!.appendingPathComponent(imageCoordinates).path)
                } catch {
                    let deleteError = error as NSError
                    print(deleteError)
                }
            }
        }
    }
}
