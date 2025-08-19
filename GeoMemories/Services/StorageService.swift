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
    func validate(_ entry: GeoEntry) throws(StorageServiceError)
}

class GeoEntryValidator: GeoEntryValidatorProtocol {
    func validate(_ entry: GeoEntry) throws(StorageServiceError) {
        guard !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw .invalidInput("Title cannot be empty")
        }
        
        guard entry.latitude >= -90 && entry.latitude <= 90 else {
            throw .invalidInput(
                "Latitude must be between -90 and 90 degrees"
            )
        }
        
        guard entry.longitude >= -180 && entry.longitude <= 180 else {
            throw .invalidInput(
                "Longitude must be between -180 and 180 degrees"
            )
        }
    }
}

protocol GeoEntryMapperProtocol {
    func map(
        _ entry: GeoEntry,
        to coreDataEntry: GeoEntry,
        in transaction: AsynchronousDataTransaction
    )
    
    func create(
        from entry: GeoEntry,
        in transaction: AsynchronousDataTransaction
    ) -> GeoEntry
}

class GeoEntryMapper: GeoEntryMapperProtocol {
    func map(
        _ entry: GeoEntry,
        to coreDataEntry: GeoEntry,
        in transaction: AsynchronousDataTransaction
    ) {
        coreDataEntry.id = entry.id
        coreDataEntry.title = entry.title
        coreDataEntry.description = entry.description
        coreDataEntry.latitude = entry.latitude
        coreDataEntry.longitude = entry.longitude
        coreDataEntry.mediaIds = entry.mediaIds
    }
    
    func create(
        from entry: GeoEntry,
        in transaction: AsynchronousDataTransaction
    ) -> GeoEntry {
        let geoEntry = transaction.create(Into<GeoEntry>())
        map(entry, to: geoEntry, in: transaction)
        return geoEntry
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
    func addGeoEntry(_ entry: GeoEntry) -> AnyPublisher<GeoEntry, StorageServiceError>
    func getGeoEntries() -> AnyPublisher<[GeoEntry], StorageServiceError>
    func updateGeoEntry(_ entry: GeoEntry) -> AnyPublisher<GeoEntry, StorageServiceError>
    func deleteGeoEntry(_ entry: GeoEntry) -> AnyPublisher<Void, StorageServiceError>
}

class StorageService: StorageServiceProtocol {
    private let dataStack: DataStackProtocol
    private let validator: GeoEntryValidatorProtocol
    private let mapper: GeoEntryMapperProtocol
    private let queryBuilder: QueryBuilderProtocol
    
    init(
        dataStack: DataStackProtocol = CoreStoreDefaults.dataStack,
        validator: GeoEntryValidatorProtocol = GeoEntryValidator(),
        mapper: GeoEntryMapperProtocol = GeoEntryMapper(),
        queryBuilder: QueryBuilderProtocol = QueryBuilder()
    ) {
        self.dataStack = dataStack
        self.validator = validator
        self.mapper = mapper
        self.queryBuilder = queryBuilder
    }
    
    func addGeoEntry(_ entry: GeoEntry) -> AnyPublisher<GeoEntry, StorageServiceError> {
        Future<GeoEntry, StorageServiceError> { [weak self] promise in
            guard let self else {
                promise(.failure(.noDataStack))
                return
            }
            
            do {
                try validator.validate(entry)
            } catch {
                // swiftlint:disable force_cast
                promise(.failure(error as! StorageServiceError))
            }
            
            dataStack.perform(
                asynchronous: { transaction in
                    return self.mapper.create(from: entry, in: transaction)
                },
                sourceIdentifier: nil,
                success: { geoEntry in
                    promise(.success(geoEntry))
                },
                failure: { error in
                    promise(.failure(.coreStoreError(error)))
                }
            )
        }
        .eraseToAnyPublisher()
    }
    
    func getGeoEntries() -> AnyPublisher<[GeoEntry], StorageServiceError> {
        Future<[GeoEntry], StorageServiceError> { [weak self] promise in
            guard let self else {
                promise(.failure(.noDataStack))
                return
            }
            
            dataStack.perform(
                asynchronous: { transaction in
                    return try transaction.fetchAll(self.queryBuilder.fetchAllQuery())
                },
                sourceIdentifier: nil,
                success: { geoEntries in
                    promise(.success(geoEntries))
                },
                failure: { error in
                    promise(.failure(.coreStoreError(error)))
                }
            )
        }
        .eraseToAnyPublisher()
    }
    
    func updateGeoEntry(_ entry: GeoEntry) -> AnyPublisher<GeoEntry, StorageServiceError> {
        Future<GeoEntry, StorageServiceError> { [weak self] promise in
            guard let self else {
                promise(.failure(.noDataStack))
                return
            }
            
            do {
                try validator.validate(entry)
            } catch {
                // swiftlint:disable force_cast
                promise(.failure(error as! StorageServiceError))
            }
            
            dataStack.perform(
                asynchronous: { transaction in
                    guard let existing = try transaction.fetchOne(
                        self.queryBuilder.fetchByIdQuery(entry.id)
                    ) else {
                        throw StorageServiceError.notFound
                    }
                    
                    self.mapper.map(entry, to: existing, in: transaction)
                    return existing
                },
                sourceIdentifier: nil,
                success: { updated in
                    promise(.success(updated))
                },
                failure: { error in
                    promise(.failure(.coreStoreError(error)))
                }
            )
        }
        .eraseToAnyPublisher()
    }
    
    func deleteGeoEntry(_ entry: GeoEntry) -> AnyPublisher<Void, StorageServiceError> {
        Future<Void, StorageServiceError> { [weak self] promise in
            guard let self else {
                promise(.failure(.noDataStack))
                return
            }
            
            dataStack.perform(
                asynchronous: { transaction in
                    try transaction.deleteAll(
                        self.queryBuilder.deleteByIdQuery(entry.id)
                    )
                },
                sourceIdentifier: nil,
                success: { done in
                    promise(.success(done))
                },
                failure: { error in
                    promise(.failure(.coreStoreError(error)))
                }
            )
        }
        .eraseToAnyPublisher()
    }
}
