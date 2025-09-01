//
//  Dependencies.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 28.08.2025.
//

import Foundation
import CoreStore

// This isn't a big app project and the amount of dependencies is low,
// so here I'll declare all the dependencies instead of using DI libraries
struct Dependencies {
    static let dataStack = CoreStoreDefaults.dataStack
    static let storageService: StorageServiceProtocol = StorageService()
    static let locationWorker: LocationWorker = LocationWorker()
    static let mediaFileWorker: MediaFileWorkerProtocol = MediaFileWorker(
        storageService: storageService
    )
}
