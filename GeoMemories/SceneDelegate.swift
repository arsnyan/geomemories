//
//  SceneDelegate.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 18.08.2025.
//

import UIKit
import CoreStore
import Combine
import OSLog

protocol CoreStoreConfiguratorProtocol {
    var dataStack: DataStack! { get }
    func configureCoreStore()
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate, CoreStoreConfiguratorProtocol {
    internal var dataStack: DataStack!
    private var cancellables = Set<AnyCancellable>()
    
    var window: UIWindow?
    
    let logger = Logger(subsystem: "GeoMemories", category: "SceneDelegate")

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        configureCoreStore()
        
        window?.makeKeyAndVisible()
    }
    
    private func setupRootViewController() {
        let mainViewController = HomeConfigurator.shared.createScene(with: dataStack)

        let navigationController = UINavigationController(rootViewController: mainViewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    private func showAlert(_ error: Error) {
        let alertController = UIAlertController(
            title: String(localized: "error"),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(
                title: String(localized: "ok"),
                style: .default
            )
        )
        window?.rootViewController?.present(alertController, animated: true)
    }
    
    private func configureDataStack() {
        dataStack = DataStack(
            CoreStoreSchema(
                modelVersion: "V1",
                entities: [
                    Entity<GeoEntry>(
                        "GeoEntry",
                        uniqueConstraints: [[\.$id]]
                    ),
                    Entity<MediaEntry>(
                        "MediaEntry",
                        uniqueConstraints: [[\.$linkedGeoEntry]]
                    )
                ],
                versionLock: [
                    "GeoEntry": [
                        0xfd36820f96da7d07,
                        0x20e82d66fa4b9573,
                        0xfab5df6385000409,
                        0x49d8668612e8e979
                    ],
                    "MediaEntry": [
                        0xbff9a08a10de99ab,
                        0xde044bd40d4c8fc2,
                        0x6fbb53aff57dc915,
                        0xa0f50dc9884819b5
                    ]
                ]
            )
        )
    }
    
    internal func configureCoreStore() {
        configureDataStack()
        
        dataStack.reactive
            .addStorage(
                SQLiteStore(
                    fileName: "core_data.sql",
                    localStorageOptions: .recreateStoreOnModelMismatch
                )
            )
            .sink(
                receiveCompletion: { [unowned self] completion in
                    switch completion {
                    case .finished:
                        logger.info("DataStack initialized successfully")
                        setupRootViewController()
                    case .failure(let error):
                        logger.error("Failed to initialized DataStack:\n\(error)")
                        showAlert(error)
                    }
                },
                receiveValue: { [weak self] progress in
                    switch progress {
                    case .migrating(_, let nsProgress):
                        let formattedProgress = round(nsProgress.fractionCompleted * 100)
                        self?.logger.trace("Migration progress: \(formattedProgress) %")
                    case .finished(_, let migrationRequired):
                        self?.logger.trace(
                            "Migration finished. Required migration:\n\(migrationRequired)"
                        )
                    }
                }
            )
            .store(in: &cancellables)
        
        CoreStoreDefaults.dataStack = dataStack
    }
}
