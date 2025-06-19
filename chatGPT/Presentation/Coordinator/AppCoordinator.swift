//
//  AppCoordinator.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import Foundation
import UIKit
import FirebaseAuth

final class AppCoordinator {
    private let window: UIWindow
    private let getKeyUseCase: GetAPIKeyUseCase
    private let saveKeyUseCase: SaveAPIKeyUseCase
    private var navigationController: UINavigationController?
    
    init(window: UIWindow, getKeyUseCase: GetAPIKeyUseCase, saveKeyUseCase: SaveAPIKeyUseCase) {
        self.window = window
        self.getKeyUseCase = getKeyUseCase
        self.saveKeyUseCase = saveKeyUseCase
    }
    
    func start() {
        signInIfNeeded { [weak self] in
            guard let self else { return }
            if self.getKeyUseCase.execute() != nil {
                self.showMain()
            } else {
                self.showKeyInput()
            }
        }
    }

    private func signInIfNeeded(completion: @escaping () -> Void) {
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { _, _ in
                completion()
            }
        } else {
            completion()
        }
    }
    
    private func showMain() {
        let service = OpenAIService(apiKeyRepository: KeychainAPIKeyRepository())
        let repository = OpenAIRepositoryImpl(service: service)
        let contextRepository = ChatContextRepositoryImpl()
        let fetchModelsUseCase = FetchAvailableModelsUseCase(repository: repository)
        let summarizeUseCase = SummarizeMessagesUseCase(repository: repository)
        let sendChatUseCase = SendChatWithContextUseCase(
            openAIRepository: repository,
            contextRepository: contextRepository,
            summarizeUseCase: summarizeUseCase
        )

        let chatDataSource = FirebaseChatDataSource()
        let chatRepository = ChatRepositoryImpl(dataSource: chatDataSource)
        let chatUseCase = ChatUseCase(repository: chatRepository)

        let chatListVM = ChatListViewModel(useCase: chatUseCase)
        let vc = ChatListViewController(viewModel: chatListVM)
        vc.onSelectChat = { [weak self] _ in
            let chatVC = MainViewController(fetchModelsUseCase: fetchModelsUseCase,
                                            sendChatMessageUseCase: sendChatUseCase,
                                            chatUseCase: chatUseCase)
            self?.navigationController?.pushViewController(chatVC, animated: true)
        }

        let nav = UINavigationController(rootViewController: vc)
        self.navigationController = nav
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
