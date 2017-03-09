//
//  PinAnnotation.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/9/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//

import MapKit

class PinAnnotation: MKPointAnnotation
{
    override init()
    {
        super.init()
    }
    
    init(withPinAnnotation pin:Pin)
    {
        super.init()
        
        self.pin = pin
    }
}
