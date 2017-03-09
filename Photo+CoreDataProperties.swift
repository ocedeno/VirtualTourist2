//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/9/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var dateCreated: NSDate?
    @NSManaged public var imageURL: String?
    @NSManaged public var imageCoordinates: String?
    @NSManaged public var pin: PinAnnotation?

}
