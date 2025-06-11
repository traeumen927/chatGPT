import Foundation

final class ChatRepositoryImpl: ChatRepository {
    func send(message: ChatMessage, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        // TODO: API 호출 로직을 구현합니다.
    }
}
