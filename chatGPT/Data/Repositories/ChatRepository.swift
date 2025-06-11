import Foundation

protocol ChatRepository {
    func send(message: ChatMessage, completion: @escaping (Result<ChatMessage, Error>) -> Void)
}
