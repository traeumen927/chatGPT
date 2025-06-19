import Foundation
import RxSwift

final class ChatRepositoryImpl: ChatRepository {
    private let dataSource: FirebaseChatDataSource

    init(dataSource: FirebaseChatDataSource) {
        self.dataSource = dataSource
    }

    func fetchChats() -> Observable<[Chat]> {
        dataSource.fetchChats().map { $0.map { $0.toDomain() } }
    }

    func createChat(title: String) -> Observable<Chat> {
        dataSource.createChat(title: title).map { $0.toDomain() }
    }

    func appendMessage(chatID: String, message: ChatRecordMessage) -> Observable<Void> {
        let dto = ChatMessageDTO(id: message.id, text: message.text, isUser: message.isUser, createdAt: message.createdAt)
        return dataSource.appendMessage(chatID: chatID, message: dto)
    }
}

private extension ChatDTO {
    func toDomain() -> Chat {
        Chat(id: id, title: title, messages: [], createdAt: createdAt)
    }
}
