//
//  CreateEditEntryInteractor.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 20.08.2025.
//  Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Combine
import OSLog
import CoreLocation
import CoreStore

protocol CreateEditEntryBusinessLogic: SearchLocationContainerDelegate {
    func provideNavigationBarTitle()
    func provideInitialValues()
    func updateMediaItems(request: CreateEditEntry.UpdateMedia.Request)
    func saveEntry(request: CreateEditEntry.Save.Request)
    
    func clearMediaInfo()
}

protocol CreateEditEntryDataStore {
    var entry: GeoEntry? { get set }
    var mediaItems: [MediaEntry] { get set }
    var selectedCoordinates: CLLocationCoordinate2D? { get set }
}

class CreateEditEntryInteractor: CreateEditEntryBusinessLogic, CreateEditEntryDataStore {
    private let logger = Logger(subsystem: "GeoMemories", category: "CreateEditEntryInteractor")
    private let storageService = Dependencies.storageService
    private var cancellables = Set<AnyCancellable>()
    
    var entry: GeoEntry?
    var presenter: CreateEditEntryPresentationLogic?
    var worker: CreateEditEntryWorker?
    
    var mediaItems: [MediaEntry] = []
    var selectedCoordinates: CLLocationCoordinate2D?
    
    func provideNavigationBarTitle() {
        presenter?.presentNavigationBarTitle(response: .init(isEditMode: entry != nil))
    }
    
    func provideInitialValues() {
        if let entry {
            Dependencies.dataStack.perform { [weak self] transaction in
                guard let existing = transaction.fetchExisting(entry) else { return }
                self?.mediaItems = Array(existing.mediaIds)
                self?.selectedCoordinates = .init(latitude: existing.latitude, longitude: existing.longitude)
                
                let existingTitle = existing.title
                let existingDescription = existing.description
                DispatchQueue.main.async {
                    self?.presenter?.presentInitialValues(
                        response: .init(
                            title: existingTitle,
                            description: existingDescription
                        )
                    )
                }
            } completion: { [weak self] result in
                if case let .failure(error) = result {
                    self?.logger.error("Couldn't fetch existing entry: \(error)")
                }
            }
        }
    }
    
    func updateMediaItems(request: CreateEditEntry.UpdateMedia.Request) {
        self.mediaItems = request.mediaItems
    }
    
    func saveEntry(request: CreateEditEntry.Save.Request) {
        guard let coordinate = selectedCoordinates else {
            logger.error("Save failed: Location is missing")
            return
        }
        
        let entryToEdit = self.entry
        
        Dependencies.dataStack.perform(
            asynchronous: { [weak self] transaction -> GeoEntry in
                guard let self else { fatalError("Self was definitely nil") }
                
                let geoEntry: GeoEntry
                if let entryToEdit, let existing = transaction.fetchExisting(entryToEdit) {
                    geoEntry = existing
                } else {
                    geoEntry = transaction.create(Into<GeoEntry>())
                }
                
                geoEntry.title = request.title
                geoEntry.description = request.description
                geoEntry.latitude = coordinate.latitude
                geoEntry.longitude = coordinate.longitude
                let mediaSet: [MediaEntry] = mediaItems.compactMap { media in
                    return transaction.fetchExisting(media)
                }
                geoEntry.mediaIds = Set(mediaSet)
                return geoEntry
            },
            completion: { [weak self] completion in
                switch completion {
                case .success(_):
                    self?.presenter?.unpresentCurrentView()
                    NotificationCenter.default.post(name: NSNotification.Name("EntriesUpdated"), object: nil)
                case .failure(let error):
                    self?.logger.error("Saving entry failed: \(error)")
                }
            }
        )
    }
    
    func clearMediaInfo() {
        CoreStoreDefaults.dataStack.perform(
            asynchronous: { [weak self] transaction in
                guard let self else { return }
                guard entry == nil else { return }
                
                mediaItems.forEach { mediaEntry in
                    let existing = transaction.fetchExisting(mediaEntry)
                    transaction.delete(existing)
                }
            },
            completion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.error("There was an error deleting media: \(error)")
                }
            }
        )
    }
    
    func didUpdateLocation(coordinate: CLLocationCoordinate2D?) {
        selectedCoordinates = coordinate
    }
}
