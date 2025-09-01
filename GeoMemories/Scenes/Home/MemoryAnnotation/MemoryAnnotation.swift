//
//  MemoryAnnotation.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 20.08.2025.
//

import MapKit

class MemoryAnnotation: NSObject, MKAnnotation {
    var entryTitle: String?
    var entryDescription: String
    var coordinate: CLLocationCoordinate2D
    var media: [MediaEntry]
    var icon: UIImage?
    // I'll keep a ref to a geo entry here despite duplicating all the properties,
    // so that I don't perform unnecessary storage operations in CoreStore for no gain.
    var geoEntry: GeoEntry
    
    init(
        geoEntry: GeoEntry,
        title: String?,
        description: String,
        latitude: Double,
        longitude: Double,
        media: [MediaEntry],
        icon: UIImage? = nil
    ) {
        self.geoEntry = geoEntry
        self.entryTitle = title
        self.entryDescription = description
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.media = media
        
        self.icon = icon
    }
}
