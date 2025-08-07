import Foundation
import RxSwift
import RxRelay

final class MenuViewModel {
    // Outputs
    let conversations = BehaviorRelay<[ConversationSummary]>(value: [])
    let availableModels = BehaviorRelay<[ModelConfig]>(value: [])
    let selectedModel: BehaviorRelay<OpenAIModel>
    let streamEnabled: BehaviorRelay<Bool>
    private(set) var currentConversationID: String?
    private let draftExists: Bool

    // UseCases
    private let observeConversationsUseCase: ObserveConversationsUseCase
    private let signOutUseCase: SignOutUseCase
    private let fetchModelsUseCase: FetchModelConfigsUseCase
    private let updateTitleUseCase: UpdateConversationTitleUseCase
    private let deleteConversationUseCase: DeleteConversationUseCase
    private let fetchMessagesUseCase: FetchConversationMessagesUseCase
    private let disposeBag = DisposeBag()

    init(observeConversationsUseCase: ObserveConversationsUseCase,
         signOutUseCase: SignOutUseCase,
         fetchModelsUseCase: FetchModelConfigsUseCase,
         updateTitleUseCase: UpdateConversationTitleUseCase,
         deleteConversationUseCase: DeleteConversationUseCase,
         fetchMessagesUseCase: FetchConversationMessagesUseCase,
         selectedModel: OpenAIModel,
         streamEnabled: Bool,
         currentConversationID: String?,
         draftExists: Bool,
         availableModels: [ModelConfig] = []) {
        self.observeConversationsUseCase = observeConversationsUseCase
        self.signOutUseCase = signOutUseCase
        self.fetchModelsUseCase = fetchModelsUseCase
        self.updateTitleUseCase = updateTitleUseCase
        self.deleteConversationUseCase = deleteConversationUseCase
        self.fetchMessagesUseCase = fetchMessagesUseCase
        self.currentConversationID = currentConversationID
        self.draftExists = draftExists
        self.selectedModel = BehaviorRelay(value: selectedModel)
        self.streamEnabled = BehaviorRelay(value: streamEnabled)
        self.availableModels.accept(availableModels)
    }

    func load() {
        var initial: [ConversationSummary] = []
        if currentConversationID == nil || draftExists {
            let draft = ConversationSummary(id: "draft", title: "새로운 대화", timestamp: Date())
            initial.append(draft)
        }
        conversations.accept(initial)

        observeConversationsUseCase.execute()
            .flatMapLatest { [weak self] list -> Single<[ConversationSummary]> in
                guard let self else { return .just(list) }
                return self.sortConversationsByLastQuestion(list)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] list in
                guard let self else { return }
                var items = list
                if self.currentConversationID == nil || self.draftExists {
                    let draft = ConversationSummary(id: "draft", title: "새로운 대화", timestamp: Date())
                    items.insert(draft, at: 0)
                }
                self.conversations.accept(items)
            })
            .disposed(by: disposeBag)
    }

    func loadModels() {
        fetchModelsUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] models in
                self?.availableModels.accept(models)
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    private func sortConversationsByLastQuestion(_ list: [ConversationSummary]) -> Single<[ConversationSummary]> {
        guard !list.isEmpty else { return .just([]) }
        let singles = list.map { summary in
            fetchMessagesUseCase.execute(conversationID: summary.id)
                .map { messages -> (ConversationSummary, Date) in
                    let lastUserDate = messages.last { $0.role == .user }?.timestamp ?? summary.timestamp
                    return (summary, lastUserDate)
                }
        }
        return Single.zip(singles)
            .map { results in
                results.sorted { $0.1 > $1.1 }.map { $0.0 }
            }
    }

    func selectConversation(id: String) {
        currentConversationID = id == "draft" ? nil : id
    }

    func signOut() throws {
        try signOutUseCase.execute()
    }

    func updateTitle(id: String, title: String) {
        updateTitleUseCase.execute(conversationID: id, title: title)
            .subscribe()
            .disposed(by: disposeBag)
    }

    func deleteConversation(id: String) -> Single<Bool> {
        deleteConversationUseCase.execute(conversationID: id)
            .map { [weak self] in
                let wasCurrent = self?.currentConversationID == id
                if wasCurrent { self?.currentConversationID = nil }
                return wasCurrent
            }
    }
}
