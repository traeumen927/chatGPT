import XCTest
import RxSwift
@testable import chatGPT

// Stub types implementing required protocols
final class StubSendChatWithContextUseCase {
    func execute(prompt: String, model: OpenAIModel, stream: Bool, preference: String?, images: [Data], files: [Data], completion: @escaping (Result<String, Error>) -> Void) {}
    func stream(prompt: String, model: OpenAIModel, preference: String?, images: [Data], files: [Data]) -> Observable<String> { .empty() }
    func finalize(prompt: String, reply: String, model: OpenAIModel) {}
}

final class StubSummarizeMessagesUseCase {}
final class StubSaveConversationUseCase {}
final class StubAppendMessageUseCase {}
final class StubFetchConversationMessagesUseCase {}
final class StubChatContextRepository: ChatContextRepository {
    var messages: [Message] = []
    var summary: String? = nil
    func append(role: RoleType, content: String) {}
    func updateSummary(_ summary: String) {}
    func replace(messages: [Message], summary: String?) {}
    func trim(to maxCount: Int) {}
    func clear() {}
}
final class StubCalculatePreferenceUseCase {}
final class StubUpdateUserPreferenceUseCase {}
final class StubUploadFilesUseCase {}
final class StubGenerateImageUseCase {}
final class StubDetectImageRequestUseCase {
    func execute(prompt: String) -> Single<Bool> { .just(false) }
}

final class ChatViewModelPreferenceTextTests: XCTestCase {
    func test_preferenceText_sorts_and_truncates() {
        let vm = ChatViewModel(
            sendMessageUseCase: StubSendChatWithContextUseCase(),
            summarizeUseCase: StubSummarizeMessagesUseCase(),
            saveConversationUseCase: StubSaveConversationUseCase(),
            appendMessageUseCase: StubAppendMessageUseCase(),
            fetchMessagesUseCase: StubFetchConversationMessagesUseCase(),
            contextRepository: StubChatContextRepository(),
            calculatePreferenceUseCase: StubCalculatePreferenceUseCase(),
            updatePreferenceUseCase: StubUpdateUserPreferenceUseCase(),
            uploadFilesUseCase: StubUploadFilesUseCase(),
            generateImageUseCase: StubGenerateImageUseCase(),
            detectImageRequestUseCase: StubDetectImageRequestUseCase()
        )
        let now = Date().timeIntervalSince1970
        let events = [
            PreferenceEvent(key: "banana", relation: .like, timestamp: now - 30),
            PreferenceEvent(key: "apple", relation: .avoid, timestamp: now - 10),
            PreferenceEvent(key: "orange", relation: .want, timestamp: now - 20),
            PreferenceEvent(key: "cake", relation: .like, timestamp: now)
        ]
        let text = vm.preferenceText(from: events)
        XCTAssertEqual(text, "like: cake, avoid: apple, want: orange")
    }
}
