//
//  LocationCellViewModel.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 21.08.2025.
//

import Foundation
import MapKit
import Contacts

protocol LocationCellViewModelProtocol {
    var mapItem: MKMapItem { get }
    var height: Double { get }
    var description: String { get }
    
    init(mapItem: MKMapItem)
}

struct LocationCellViewModel: LocationCellViewModelProtocol {
    private(set) var mapItem: MKMapItem
    
    var height: Double {
        60
    }
    
    var description: String {
        var description = ""
        if #available(iOS 26.0, *) {
            description = mapItem.address?.fullAddress
                ?? coordinatesToString(mapItem.location.coordinate)
        } else {
            if let postalAddress = mapItem.placemark.postalAddress {
                let formatter = CNPostalAddressFormatter()
                description = formatter.string(from: postalAddress)
            } else {
                let placemark = mapItem.placemark
                let addressParts = [
                    placemark.name,
                    placemark.thoroughfare,
                    placemark.subThoroughfare,
                    placemark.locality,
                    placemark.subAdministrativeArea,
                    placemark.administrativeArea,
                    placemark.postalCode,
                    placemark.country
                ]
                
                let fullAddress = addressParts.compactMap(\.self).joined(
                    separator: ", "
                )
                description = fullAddress
            }
        }
        return description
    }
    
    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
    }
    
    func coordinatesToString(_ coord: CLLocationCoordinate2D) -> String {
        let lat = coord.latitude
        let lng = coord.longitude
        // Always show the sign (+ or -) of the coordinate regex
        return String(format: "%+.6f, %+.6f", lat, lng)
    }
}
