import Foundation
import RxSwift

protocol ChatRepository {
    func fetchChats() -> Observable<[Chat]>
    func createChat(title: String) -> Observable<Chat>
    func appendMessage(chatID: String, message: ChatRecordMessage) -> Observable<Void>
}
