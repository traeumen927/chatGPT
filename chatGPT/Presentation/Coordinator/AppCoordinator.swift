//
//  AppCoordinator.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import Foundation
import UIKit

final class AppCoordinator {
    private let window: UIWindow
    private let getKeyUseCase: GetAPIKeyUseCase
    private let saveKeyUseCase: SaveAPIKeyUseCase
    
    init(window: UIWindow, getKeyUseCase: GetAPIKeyUseCase, saveKeyUseCase: SaveAPIKeyUseCase) {
        self.window = window
        self.getKeyUseCase = getKeyUseCase
        self.saveKeyUseCase = saveKeyUseCase
    }
    
    func start() {
        if getKeyUseCase.execute() != nil {
            showMain()
        } else {
            showKeyInput()
        }
    }
    
    private func showMain() {
        let service = OpenAIService(apiKeyRepository: KeychainAPIKeyRepository())
        let repository = OpenAIRepositoryImpl(service: service)
        let fetchModelsUseCase = FetchAvailableModelsUseCase(repository: repository)
        let sendChatUseCase = SendChatMessageUseCase(repository: repository)
        
        let vc = MainViewController(
            fetchModelsUseCase: fetchModelsUseCase,
            sendChatMessageUseCase: sendChatUseCase
        )
        
        let nav = UINavigationController(rootViewController: vc)
        window.rootViewController = nav
        window.makeKeyAndVisible()
    }
    
    private func showKeyInput() {
        let vc = APIKeyInputViewController(saveUseCase: saveKeyUseCase) { [weak self] in
            self?.showMain()
        }
        window.rootViewController = vc
        window.makeKeyAndVisible()
    }
}
