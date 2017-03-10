//
//  PinAnnotation+CoreDataClass.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/9/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//

import Foundation
import CoreData


public class PinAnnotation: NSManagedObject
{
    struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(context: NSManagedObjectContext) {
        guard let pinEntity = NSEntityDescription.entity(forEntityName: "PinAnnotation", in: context) else {
            fatalError("Could not create Pin Entity Description!")
        }
        
        super.init(entity: pinEntity, insertInto: context)
    }
    
    init(dictionary: [String:AnyObject], context: NSManagedObjectContext) {
        guard let pinEntity = NSEntityDescription.entity(forEntityName: "PinAnnotation", in: context) else {
            fatalError("Could not create Pin Entity Description!")
        }
        
        super.init(entity: pinEntity, insertInto: context)
        
        latitude = (dictionary[Keys.latitude] as! Float as NSNumber?)!
        longitude = (dictionary[Keys.longitude] as! Float as NSNumber?)!
    }
}
