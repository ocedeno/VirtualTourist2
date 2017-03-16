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
        static let mURL = "mURL"
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
        
        dateCreated = dictionary[Keys.dateCreated] as? NSDate
        imageData = dictionary[Keys.imageData] as? NSData
        mURL = dictionary[Keys.mURL] as? String
    }
    
    init(insertInto context: NSManagedObjectContext?, mURL: String) {
        
        guard let photoEntity = NSEntityDescription.entity(forEntityName: "Photo", in: context!) else
        {
            fatalError("Could not create Photo Entity Description!")
        }
        
        super.init(entity: photoEntity, insertInto: context)
        
        self.mURL = mURL
    }
}
