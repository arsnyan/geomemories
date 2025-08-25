//
//  SearchLocationContainerConfigurator.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 24.08.2025.
//

import Foundation

@MainActor
final class SearchLocationContainerConfigurator {
    static let shared = SearchLocationContainerConfigurator()
    
    private init() {}
    
    func configure(viewController: SearchLocationContainerViewController) {
        let interactor = SearchLocationContainerInteractor()
        let presenter = SearchLocationContainerPresenter()
        let router = SearchLocationContainerRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
}
