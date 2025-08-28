//
//  Dependencies.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 28.08.2025.
//

import Foundation

// This isn't a big app project and the amount of dependencies is low,
// so here I'll declare all the dependencies instead of using DI libraries
struct Dependencies {
    static let storageService: StorageServiceProtocol = StorageService()
    static let fileService: FileServiceProtocol = FileService(
        storageService: storageService
    )
}
