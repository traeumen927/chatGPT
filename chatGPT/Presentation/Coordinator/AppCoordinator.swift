//
//  AppCoordinator.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import Foundation
import UIKit
import RxSwift

final class AppCoordinator {
    private let window: UIWindow
    private let getKeyUseCase: GetAPIKeyUseCase
    private let saveKeyUseCase: SaveAPIKeyUseCase
    private let authRepository: AuthRepository
    private let disposeBag = DisposeBag()

    init(window: UIWindow,
         getKeyUseCase: GetAPIKeyUseCase,
         saveKeyUseCase: SaveAPIKeyUseCase,
         authRepository: AuthRepository) {
        self.window = window
        self.getKeyUseCase = getKeyUseCase
        self.saveKeyUseCase = saveKeyUseCase
        self.authRepository = authRepository
    }
    
    func start() {
        authRepository.observeAuthState()
            .distinctUntilChanged { $0?.uid == $1?.uid }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] user in
                guard let self = self else { return }
                if user == nil {
                    self.showLogin()
                } else if self.getKeyUseCase.execute() != nil {
                    self.showMain()
                } else {
                    self.showKeyInput()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func showMain() {
        let service = OpenAIService(apiKeyRepository: KeychainAPIKeyRepository())
        let repository = OpenAIRepositoryImpl(service: service)
        let contextRepository = ChatContextRepositoryImpl()
        let modelConfigRepository = FirestoreModelConfigRepository()
        let fetchModelsUseCase = FetchModelConfigsUseCase(
            configRepository: modelConfigRepository,
            openAIRepository: repository
        )
        let summarizeUseCase = SummarizeMessagesUseCase(repository: repository)
        let sendChatUseCase = SendChatWithContextUseCase(
            openAIRepository: repository,
            contextRepository: contextRepository,
            summarizeUseCase: summarizeUseCase
        )
        let getCurrentUserUseCase = GetCurrentUserUseCase(repository: authRepository)
        
        let preferenceRepository = FirestoreUserPreferenceRepository()
        let eventRepository = FirestorePreferenceEventRepository()
        let statusRepository = FirestorePreferenceStatusRepository()
        let translationRepository = OpenAITranslationRepository(repository: repository)

        let profileRepository = FirestoreUserProfileRepository()
        let fetchProfileUseCase = FetchUserProfileUseCase(
            repository: profileRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let updateProfileUseCase = UpdateUserProfileUseCase(
            repository: profileRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let calculatePreferenceUseCase = CalculatePreferenceUseCase(
            eventRepository: eventRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let updatePreferenceUseCase = UpdateUserPreferenceUseCase(
            repository: preferenceRepository,
            eventRepository: eventRepository,
            statusRepository: statusRepository,
            getCurrentUserUseCase: getCurrentUserUseCase,
            translationRepository: translationRepository
        )
        let fetchPreferenceEventsUseCase = FetchPreferenceEventsUseCase(
            repository: eventRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let fetchPreferenceStatusUseCase = FetchPreferenceStatusUseCase(
            repository: statusRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let updatePreferenceStatusUseCase = UpdatePreferenceStatusUseCase(
            repository: statusRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let deletePreferenceEventUseCase = DeletePreferenceEventUseCase(
            repository: eventRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let deletePreferenceStatusUseCase = DeletePreferenceStatusUseCase(
            repository: statusRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let conversationRepository = FirestoreConversationRepository()
        
        let saveConversationUseCase = SaveConversationUseCase(
            repository: conversationRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let appendMessageUseCase = AppendMessageUseCase(
            repository: conversationRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let fetchConversationMessagesUseCase = FetchConversationMessagesUseCase(
            repository: conversationRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let observeConversationsUseCase = ObserveConversationsUseCase(
            repository: conversationRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let updateTitleUseCase = UpdateConversationTitleUseCase(
            repository: conversationRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let deleteConversationUseCase = DeleteConversationUseCase(
            repository: conversationRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let fileRepository = FirebaseFileRepository()
        let uploadFilesUseCase = UploadFilesUseCase(repository: fileRepository,
                                                   getCurrentUserUseCase: getCurrentUserUseCase)
        let generateImageUseCase = GenerateImageUseCase(repository: repository)
        let detectImageRequestUseCase = DetectImageRequestUseCase(repository: repository)
        observeConversationsUseCase.execute()
            .subscribe()
            .disposed(by: disposeBag)
        let signOutUseCase = SignOutUseCase(repository: authRepository)
        let imageRepository = KingfisherImageRepository()
        let loadUserImageUseCase = LoadUserProfileImageUseCase(
            imageRepository: imageRepository,
            getCurrentUserUseCase: getCurrentUserUseCase
        )
        let observeAuthStateUseCase = ObserveAuthStateUseCase(repository: authRepository)
        let markdownRepository = SwiftMarkdownRepository()
        let parseMarkdownUseCase = ParseMarkdownUseCase(repository: markdownRepository)

        let vc = MainViewController(
            fetchModelsUseCase: fetchModelsUseCase,
            sendChatMessageUseCase: sendChatUseCase,
            summarizeUseCase: summarizeUseCase,
            saveConversationUseCase: saveConversationUseCase,
            appendMessageUseCase: appendMessageUseCase,
            fetchConversationMessagesUseCase: fetchConversationMessagesUseCase,
            contextRepository: contextRepository,
            observeConversationsUseCase: observeConversationsUseCase,
            signOutUseCase: signOutUseCase,
            updateTitleUseCase: updateTitleUseCase,
            deleteConversationUseCase: deleteConversationUseCase,
            loadUserImageUseCase: loadUserImageUseCase,
            observeAuthStateUseCase: observeAuthStateUseCase,
            parseMarkdownUseCase: parseMarkdownUseCase,
            calculatePreferenceUseCase: calculatePreferenceUseCase,
            updatePreferenceUseCase: updatePreferenceUseCase,
            fetchProfileUseCase: fetchProfileUseCase,
            updateProfileUseCase: updateProfileUseCase,
            uploadFilesUseCase: uploadFilesUseCase,
            generateImageUseCase: generateImageUseCase,
            detectImageRequestUseCase: detectImageRequestUseCase,
            fetchPreferenceEventsUseCase: fetchPreferenceEventsUseCase,
            fetchPreferenceStatusUseCase: fetchPreferenceStatusUseCase,
            updatePreferenceStatusUseCase: updatePreferenceStatusUseCase,
            deletePreferenceEventUseCase: deletePreferenceEventUseCase,
            deletePreferenceStatusUseCase: deletePreferenceStatusUseCase
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

    private func showLogin() {
        let vc = LoginViewController { [weak self] in
            guard let self = self else { return }
            if self.getKeyUseCase.execute() != nil {
                self.showMain()
            } else {
                self.showKeyInput()
            }
        }
        window.rootViewController = vc
        window.makeKeyAndVisible()
    }
}

