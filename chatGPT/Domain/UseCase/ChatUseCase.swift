import Foundation
import RxSwift

final class ChatUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func fetchChats() -> Observable<[Chat]> {
        repository.fetchChats()
    }

    func createChat(title: String) -> Observable<Chat> {
        repository.createChat(title: title)
    }

    func appendMessage(chatID: String, message: ChatRecordMessage) -> Observable<Void> {
        repository.appendMessage(chatID: chatID, message: message)
    }
}
