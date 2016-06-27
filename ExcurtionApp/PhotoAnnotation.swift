//
//  PhotoAnnotation.swift
//  ExcurtionApp
//
//  Created by Артмеий Шлесберг on 26/06/16.
//  Copyright © 2016 Shlesberg. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class PhotoAnnotation: NSObject, MKAnnotation {
    let title: String?
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let pointId : String
    let position : Int
    
    init(title: String, locationName: String, pointId: String, coordinate: CLLocationCoordinate2D, pos : Int) {
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate
        self.pointId = pointId
        self.position = pos
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
}