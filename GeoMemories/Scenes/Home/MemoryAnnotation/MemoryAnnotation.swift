//
//  MemoryAnnotation.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 20.08.2025.
//

import MapKit

class MemoryAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var image: UIImage?
    
    init(latitude: Double, longitude: Double, image: UIImage? = nil) {
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.image = image
    }
}
