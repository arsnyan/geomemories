//
//  SceneDelegate.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 18.08.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        // window?.rootViewController =
        window?.makeKeyAndVisible()
    }
}
