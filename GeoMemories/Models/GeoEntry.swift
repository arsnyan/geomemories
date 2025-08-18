//
//  GeoEntry.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 18.08.2025.
//

import Foundation
import CoreStore

class GeoEntry: CoreStoreObject {
    @Field.Stored("id")
    var id: UUID = UUID()
    
    @Field.Stored("title")
    var title: String = ""
    
    @Field.Stored("entry_description")
    var description: String = ""
    
    @Field.Stored("latitude")
    var latitude: Double = 0.0
    
    @Field.Stored("longitude")
    var longitude: Double = 0.0
    
    @Field.Relationship("media_entries", inverse: \MediaEntry.$linkedGeoEntry)
    var imageIds: Set<MediaEntry>
}
