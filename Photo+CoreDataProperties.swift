//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/9/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//

import Foundation
import CoreData


extension Photo
{
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo>
    {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var dateCreated: NSDate?
    @NSManaged public var imageData: NSData?
    @NSManaged public var pin: PinAnnotation?

}
