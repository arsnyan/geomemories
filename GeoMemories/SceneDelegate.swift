//
//  SceneDelegate.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 18.08.2025.
//

import UIKit
import CoreStore
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var dataStack: DataStack!
    private var cancellables = Set<AnyCancellable>()
    
    var window: UIWindow?

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
//        let mainViewController = HomeConfigurator.createScene(dataStack)
//
//        let navigationController = UINavigationController(rootViewController: mainViewController)
//        
//        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    private func showAlert(_ error: Error) {
        let ac = UIAlertController(title: "error", message: error.localizedDescription, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "ok", style: .default))
        window?.rootViewController?.present(ac, animated: true)
    }
    
    private func configureDataStack() {
        dataStack = DataStack(
            CoreStoreSchema(modelVersion: "V1", entities: [
                Entity<GeoEntry>("GeoEntry"),
                Entity<MediaEntry>("MediaEntry")
            ])
        )
    }
    
    private func configureCoreStore() {
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
                        print("DataStack initialized successfully")
                        setupRootViewController()
                    case .failure(let error):
                        print("Failed to initialized DataStack:", error)
                        showAlert(error)
                    }
                },
                receiveValue: { progress in
                    switch progress {
                    case .migrating(let storage, let nsProgress):
                        let formattedProgress = round(nsProgress.fractionCompleted * 100)
                        print("Migration progress: \(formattedProgress) %")
                    case .finished(let storage, let migrationRequired):
                        print(
                            "Migration finished. Required migration: ",
                            migrationRequired
                        )
                    }
                }
            )
            .store(in: &cancellables)
        
        CoreStoreDefaults.dataStack = dataStack
    }
}
