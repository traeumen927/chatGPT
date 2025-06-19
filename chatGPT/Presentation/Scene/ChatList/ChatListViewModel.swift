import Foundation
import RxSwift
import RxCocoa

final class ChatListViewModel {
    struct Input {
        let viewDidLoad: Observable<Void>
    }

    struct Output {
        let chats: Driver<[Chat]>
    }

    private let useCase: ChatUseCase

    init(useCase: ChatUseCase) {
        self.useCase = useCase
    }

    func transform(input: Input) -> Output {
        let chats = input.viewDidLoad
            .flatMapLatest { self.useCase.fetchChats() }
            .asDriver(onErrorJustReturn: [])
        return Output(chats: chats)
    }
}
