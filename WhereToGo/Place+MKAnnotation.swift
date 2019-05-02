//
//  Place+MKAnnotation.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 23.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import Foundation
import MapKit

extension Place: MKAnnotation {
    
    // Required. The center point (specified as a map coordinate) of the annotation.
    public var coordinate: CLLocationCoordinate2D
    {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
  
    public var subtitle: String?
    {
        return self.address
    }
}
