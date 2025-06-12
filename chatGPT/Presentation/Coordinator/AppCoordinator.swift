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
        let main = MainViewController()
        let navigationController = UINavigationController(rootViewController: main)
        let menu = MenuViewController()
        let container = SideMenuContainerViewController(contentViewController: navigationController,
                                                        menuViewController: menu)
        window.rootViewController = container
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
