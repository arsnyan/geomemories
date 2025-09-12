//
//  EntryDetailsViewModel.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 02.09.2025.
//

import Foundation
import CoreStore
import CoreLocation

enum EntryDetailsSection: Int, CaseIterable {
    case userInfo = 0
    case mediaCards
    case mapView
    case placeInfo
    
    var title: String {
        switch self {
        case .userInfo:
            String(localized: "userInfoSection")
        case .mediaCards:
            String(localized: "mediaCardsSection")
        case .mapView:
            String(localized: "mapViewSection")
        case .placeInfo:
            String(localized: "placeInfoSection")
        }
    }
}

protocol EntryDetailsViewModelProtocol: AnyObject {
    var wikiDescription: Box<String?> { get set }
    var title: String { get }
    var description: String { get }
    var mediaCards: [MediaCardViewModelProtocol] { get }
    var coordinates: CLLocationCoordinate2D { get }
    
    init(entry: GeoEntry)
    
    func loadInitialWikiData()
}

final class EntryDetailsViewModel: EntryDetailsViewModelProtocol {
    internal struct Entry {
        let title: String
        let description: String
        let mediaCards: [MediaCardViewModelProtocol]
        let latitude: Double
        let longitude: Double
    }
    
    private let wikipediaService = Dependencies.wikipediaService
    
    private var entry: Entry!
    
    var wikiDescription: Box<String?> = Box(nil)
    
    var title: String {
        entry.title
    }
    
    var description: String {
        entry.description
    }
    
    var mediaCards: [MediaCardViewModelProtocol] {
        entry.mediaCards
    }
    
    var coordinates: CLLocationCoordinate2D {
        .init(latitude: entry.latitude, longitude: entry.longitude)
    }
    
    init(entry: GeoEntry) {
        let existingEntry = Dependencies.dataStack.fetchExisting(entry)!
        
        let cards = existingEntry.mediaIds.map { MediaCardViewModel(mediaEntry: $0) }
        self.entry = Entry(
            title: existingEntry.title,
            description: existingEntry.description,
            mediaCards: cards,
            latitude: existingEntry.latitude,
            longitude: existingEntry.longitude
        )
    }
    
    func loadInitialWikiData() {
        wikipediaService.findSuitableDescription(
            for: CLLocationCoordinate2D(
                latitude: self.entry.latitude,
                longitude: self.entry.longitude
            ),
            completionHandler: { [weak self] desc in
                DispatchQueue.main.async {
                    self?.wikiDescription.value = desc
                }
            }
        )
    }
}
