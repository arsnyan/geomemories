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

protocol CreateEditEntryBusinessLogic {
    func provideNavigationBarTitle()
}

protocol CreateEditEntryDataStore {
    var entry: GeoEntry? { get set }
}

class CreateEditEntryInteractor: CreateEditEntryBusinessLogic, CreateEditEntryDataStore {
    private let logger = Logger(subsystem: "GeoMemories", category: "CreateEditEntryInteractor")
    private var cancellables = Set<AnyCancellable>()
    
    var entry: GeoEntry?
    var presenter: CreateEditEntryPresentationLogic?
    var worker: CreateEditEntryWorker?
    
    func provideNavigationBarTitle() {
        presenter?.presentNavigationBarTitle(response: .init(isEditMode: entry != nil))
    }
}
