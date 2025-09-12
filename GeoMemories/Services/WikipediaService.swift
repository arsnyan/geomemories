//
//  WikipediaService.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 02.09.2025.
//

import Foundation
import CoreLocation
import MapKit
import Combine
import OSLog

protocol WikipediaServiceProtocol {
    func findSuitableDescription(
        for coordinates: CLLocationCoordinate2D,
        completionHandler: @escaping (String?) -> Void
    )
}

final internal class Coordinate2DRepresentable: NSObject {
    let latitude: Double
    let longitude: Double
    
    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Coordinate2DRepresentable else { return false }
        return latitude == other.latitude && longitude == other.longitude
    }
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(latitude)
        hasher.combine(longitude)
        return hasher.finalize()
    }
}

final class WikipediaService: WikipediaServiceProtocol {
    private let locationWorker: LocationWorker
    private let logger = Logger(subsystem: "GeoMemories", category: "WikipediaService")
    private var cancellables = Set<AnyCancellable>()
    
    internal init(locationWorker: LocationWorker = Dependencies.locationWorker) {
        self.locationWorker = locationWorker
    }
    
    func findSuitableDescription(
        for coordinates: CLLocationCoordinate2D,
        completionHandler: @escaping (String?) -> Void
    ) {
        let coordsQuery = "\(coordinates.latitude), \(coordinates.longitude)"
        locationWorker.findLocations(with: coordsQuery)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.logger.error("Failed to find location: \(error)")
                        completionHandler(nil)
                        return
                    }
                },
                receiveValue: { [weak self] mapItems in
                    guard let self, let mapItem = mapItems.first else {
                        completionHandler(nil)
                        return
                    }
                    
                    if #available(iOS 26.0, *) {
                        Task { [weak self] in
                            guard let self else {
                                completionHandler(nil)
                                return
                            }
                            
                            if let cityWithContext = mapItem.addressRepresentations?.cityWithContext {
                                if let description = await fetchDescription(query: cityWithContext) {
                                    completionHandler(description)
                                    return
                                }
                            } else if let region = mapItem.addressRepresentations?.regionName {
                                if let description = await fetchDescription(query: region) {
                                    completionHandler(description)
                                    return
                                }
                            } else {
                                completionHandler(nil)
                                return
                            }
                        }
                    } else {
                        let placemark = mapItem.placemark
                        let addressParts = [
                            placemark.name, placemark.thoroughfare,
                            placemark.subThoroughfare, placemark.locality,
                            placemark.subAdministrativeArea, placemark.administrativeArea,
                            placemark.postalCode, placemark.country
                        ]
                        Task {
                            for part in addressParts.compactMap(\.self) {
                                if let description = await self.fetchDescription(query: part) {
                                    completionHandler(description)
                                    return
                                }
                            }
                            completionHandler(nil)
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func fetchDescription(query: String) async -> String? {
        guard let link = linkWithQuery(query) else { return nil }
        guard let url = URL(string: link) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let response = try JSONDecoder().decode(WikiApiResponse.self, from: data)
            return response.query.pages.values.first?.extract
        } catch {
            return nil
        }
    }
}

private extension WikipediaService {
    func linkWithQuery(_ query: String) -> String? {
        guard let encoded = query.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) else { return nil }
        
        // swiftlint:disable line_length
        return "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro&explaintext&redirects=1&titles=\(encoded)"
    }
}
