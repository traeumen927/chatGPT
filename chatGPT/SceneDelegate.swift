//
//  SceneDelegate.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var coordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        let repository = KeychainAPIKeyRepository()
        let getUseCase = GetAPIKeyUseCase(repository: repository)
        let saveUseCase = SaveAPIKeyUseCase(repository: repository)
        let coordinator = AppCoordinator(window: window,
                                        getKeyUseCase: getUseCase,
                                        saveKeyUseCase: saveUseCase)
        self.window = window
        self.coordinator = coordinator
        coordinator.start()
    }
}
