import Foundation

protocol SendMessageUseCase {
    func execute(message: ChatMessage, completion: @escaping (Result<ChatMessage, Error>) -> Void)
}
