//
//  PinAnnotation.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/9/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//

import MapKit

class MyPinAnnotation: MKPointAnnotation
{
    var pin: PinAnnotation?
    
    override init()
    {
        super.init()
    }
    
    init(withPinAnnotation pin:PinAnnotation)
    {
        super.init()
        
        self.pin = pin
    }
}
