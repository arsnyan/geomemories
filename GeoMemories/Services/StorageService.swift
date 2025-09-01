//
//  StorageService.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 19.08.2025.
//

import Foundation
import Combine
import CoreStore
import CoreData
import CoreLocation
import OSLog

enum StorageServiceError: LocalizedError {
    case noDataStack
    case coreStoreError(Error)
    case invalidInput(String)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .noDataStack:
            "DataStack was not provided"
        case .coreStoreError(let error):
            error.localizedDescription
        case .invalidInput(let message):
            "Invalid input: \(message)"
        case .notFound:
            "Entity not found"
        }
    }
}

protocol DataStackProtocol {
    func perform<T>(
        asynchronous task: @escaping (
            _ transaction: AsynchronousDataTransaction
        ) throws(any Swift.Error) -> T,
        sourceIdentifier: Any?,
        success: @escaping (T) -> Void,
        failure: @escaping (CoreStoreError) -> Void
    )
}

extension DataStack: DataStackProtocol {}

protocol GeoEntryValidatorProtocol {
    func validate(
        title: String,
        latitude: Double,
        longitude: Double
    ) throws(StorageServiceError)
}

class GeoEntryValidator: GeoEntryValidatorProtocol {
    func validate(
        title: String,
        latitude: Double,
        longitude: Double
    ) throws(StorageServiceError) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw .invalidInput("Title cannot be empty")
        }
        
        guard latitude >= -90 && latitude <= 90 else {
            throw .invalidInput(
                "Latitude must be between -90 and 90 degrees"
            )
        }
        
        guard longitude >= -180 && longitude <= 180 else {
            throw .invalidInput(
                "Longitude must be between -180 and 180 degrees"
            )
        }
    }
}

protocol QueryBuilderProtocol {
    func fetchAllQuery() -> From<GeoEntry>
    func fetchByIdQuery(_ id: UUID) -> FetchChainBuilder<GeoEntry>
    func deleteByIdQuery(_ id: UUID) -> FetchChainBuilder<GeoEntry>
}

class QueryBuilder: QueryBuilderProtocol {
    func fetchAllQuery() -> From<GeoEntry> {
        return From<GeoEntry>()
    }
    
    func fetchByIdQuery(_ id: UUID) -> FetchChainBuilder<GeoEntry> {
        return From<GeoEntry>().where(\.$id == id)
    }
    
    func deleteByIdQuery(_ id: UUID) -> FetchChainBuilder<GeoEntry> {
        return From<GeoEntry>().where(\.$id == id)
    }
}

protocol StorageServiceProtocol {
    // MARK: - StorageServiceProtocol — GeoEntries
    func addGeoEntry(
        withTitle title: String,
        description: String,
        at coord: CLLocationCoordinate2D,
        withMedia media: Set<MediaEntry>
    ) -> AnyPublisher<GeoEntry, StorageServiceError>
    func getGeoEntries() -> AnyPublisher<[GeoEntry], StorageServiceError>
    func updateGeoEntry(
        _ entry: GeoEntry
    ) -> AnyPublisher<GeoEntry, StorageServiceError>
    func deleteGeoEntry(
        _ entry: GeoEntry
    ) -> AnyPublisher<Void, StorageServiceError>
    
    // MARK: - StorageServiceProtocol — MediaEntries
    func addMediaEntry(
        of type: MediaType,
        withPath path: String,
        for entry: GeoEntry?
    ) -> AnyPublisher<MediaEntry, StorageServiceError>
    func updateMediaEntry(
        _ entry: MediaEntry,
        toLinkWith geoEntry: GeoEntry
    ) -> AnyPublisher<MediaEntry, StorageServiceError>
    func deleteMediaEntry(
        _ entry: MediaEntry
    ) -> AnyPublisher<Void, StorageServiceError>
}

// MARK: - StorageService
class StorageService: StorageServiceProtocol {
    // MARK: - Dependencies
    private let dataStack: DataStack
    private let validator: GeoEntryValidatorProtocol
    private let queryBuilder: QueryBuilderProtocol
    
    private let logger = Logger(subsystem: "GeoMemories", category: "StorageService")
    
    init(
        dataStack: DataStack = CoreStoreDefaults.dataStack,
        validator: GeoEntryValidatorProtocol = GeoEntryValidator(),
        queryBuilder: QueryBuilderProtocol = QueryBuilder()
    ) {
        self.dataStack = dataStack
        self.validator = validator
        self.queryBuilder = queryBuilder
    }
    
    // MARK: - CRUD — Geo Entries
    
    func addGeoEntry(
        withTitle title: String,
        description: String = "",
        at coord: CLLocationCoordinate2D,
        withMedia media: Set<MediaEntry> = []
    ) -> AnyPublisher<GeoEntry, StorageServiceError> {
        do {
            try validator.validate(
                title: title,
                latitude: coord.latitude,
                longitude: coord.longitude
            )
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return dataStack.reactive.perform { transaction in
            let geoEntry = transaction.create(Into<GeoEntry>())
            geoEntry.title = title
            geoEntry.description = description
            geoEntry.latitude = coord.latitude
            geoEntry.longitude = coord.longitude
            geoEntry.mediaIds = media
            return geoEntry
        }
        .mapError({ StorageServiceError.coreStoreError($0) })
        .eraseToAnyPublisher()
    }
    
    func getGeoEntries() -> AnyPublisher<[GeoEntry], StorageServiceError> {
        dataStack.reactive.perform { transaction in
            return try transaction.fetchAll(self.queryBuilder.fetchAllQuery())
        }
        .mapError({ StorageServiceError.coreStoreError($0) })
        .eraseToAnyPublisher()
    }
    
    func updateGeoEntry(_ entry: GeoEntry) -> AnyPublisher<GeoEntry, StorageServiceError> {
        dataStack.reactive.perform { transaction in
            guard let existing = try transaction.fetchOne(
                self.queryBuilder.fetchByIdQuery(entry.id)
            ) else {
                throw StorageServiceError.notFound
            }
            existing.title = entry.title
            existing.description = entry.description
            existing.latitude = entry.latitude
            existing.longitude = entry.longitude
            existing.mediaIds = entry.mediaIds
            return existing
        }
        .mapError({ StorageServiceError.coreStoreError($0) })
        .eraseToAnyPublisher()
    }
    
    func deleteGeoEntry(_ entry: GeoEntry) -> AnyPublisher<Void, StorageServiceError> {
        dataStack.reactive.perform { transaction in
            try transaction.deleteAll(
                self.queryBuilder.deleteByIdQuery(entry.id)
            )
        }
        .mapError({ StorageServiceError.coreStoreError($0) })
        .eraseToAnyPublisher()
    }
    
    // MARK: - CRUD — Media Entries
    
    func addMediaEntry(
        of type: MediaType,
        withPath path: String,
        for entry: GeoEntry? = nil
    ) -> AnyPublisher<MediaEntry, StorageServiceError> {
        dataStack.reactive.perform { transaction in
            let mediaEntry = transaction.create(Into<MediaEntry>())
            mediaEntry.linkedGeoEntry = entry
            mediaEntry.mediaPath = path
            mediaEntry.mediaType = type.rawValue
            return mediaEntry
        }
        .mapError({ StorageServiceError.coreStoreError($0) })
        .eraseToAnyPublisher()
    }
    
    func updateMediaEntry(
        _ entry: MediaEntry,
        toLinkWith geoEntry: GeoEntry
    ) -> AnyPublisher<MediaEntry, StorageServiceError> {
        dataStack.reactive.perform { transaction in
            guard let existing = try transaction.fetchOne(
                From<MediaEntry>()
                    .where(\.$mediaPath == entry.mediaPath)
            ) else {
                throw StorageServiceError.notFound
            }
            existing.linkedGeoEntry = geoEntry
            return existing
        }
        .mapError({ StorageServiceError.coreStoreError($0) })
        .eraseToAnyPublisher()
    }
    
    func deleteMediaEntry(_ entry: MediaEntry) -> AnyPublisher<Void, StorageServiceError> {
        dataStack.reactive.perform { transaction in
            try transaction.deleteAll(
                From<MediaEntry>()
                    .where(\.$mediaPath == entry.mediaPath)
            )
        }
        .mapError({ StorageServiceError.coreStoreError($0) })
        .eraseToAnyPublisher()
    }
}
