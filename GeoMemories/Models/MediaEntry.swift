//
//  MediaEntry.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 18.08.2025.
//

import CoreStore

enum MediaType: Int, CaseIterable {
    case image = 0
    case video
}

class MediaEntry: CoreStoreObject {
    @Field.Relationship("linked_geo_entry")
    var linkedGeoEntry: GeoEntry?
    
    @Field.Stored("media_path")
    var mediaPath: String = ""
    
    @Field.Stored("media_type")
    var mediaType: Int = MediaType.image.rawValue
}
