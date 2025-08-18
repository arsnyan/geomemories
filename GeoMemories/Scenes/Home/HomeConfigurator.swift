//
//  HomeConfigurator.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 18.08.2025.
//

import Foundation
import CoreStore
import UIKit

@MainActor
final class HomeConfigurator {
    static let shared = HomeConfigurator()
    
    private init() {}
    
    func createScene(with dataStack: DataStack) -> HomeViewController {
        let viewController = HomeViewController()
        let interactor = HomeInteractor()
        let presenter = HomePresenter()
        let router = HomeRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
        
        return viewController
    }
}
