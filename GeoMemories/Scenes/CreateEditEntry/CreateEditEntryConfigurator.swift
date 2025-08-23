//
//  CreateEditEntryConfigurator.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 20.08.2025.
//

import Foundation

@MainActor
final class CreateEditEntryConfigurator {
    static let shared = CreateEditEntryConfigurator()
    
    private init() {}
    
    func configure(with viewController: CreateEditEntryViewController) {
        let interactor = CreateEditEntryInteractor()
        let presenter = CreateEditEntryPresenter()
        let router = CreateEditEntryRouter()
        
        let locationWorker = LocationWorker()
        
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        interactor.locationWorker = locationWorker
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
}
