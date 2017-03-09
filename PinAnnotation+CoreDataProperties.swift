//
//  PinAnnotation+CoreDataProperties.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/9/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//

import Foundation
import CoreData


extension PinAnnotation
{
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PinAnnotation>
    {
        return NSFetchRequest<PinAnnotation>(entityName: "PinAnnotation");
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var photos: Photo?

}
