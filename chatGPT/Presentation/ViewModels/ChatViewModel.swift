import Foundation

final class ChatViewModel {
    private let sendMessageUseCase: SendMessageUseCase
    
    init(sendMessageUseCase: SendMessageUseCase) {
        self.sendMessageUseCase = sendMessageUseCase
    }
    
    func send(message: String, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        let chatMessage = ChatMessage(role: "user", content: message)
        sendMessageUseCase.execute(message: chatMessage, completion: completion)
    }
}
