import XCTest
import RxSwift
@testable import chatGPT

// Stub types implementing required protocols
final class StubSendChatWithContextUseCase {
    func execute(prompt: String, model: OpenAIModel, stream: Bool, preference: String?, profile: String?, images: [Data], files: [Data], completion: @escaping (Result<String, Error>) -> Void) {}
    func stream(prompt: String, model: OpenAIModel, preference: String?, profile: String?, images: [Data], files: [Data]) -> Observable<String> { .empty() }
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
final class StubAnalyzeUserInputUseCase {}
final class StubUploadFilesUseCase {}
final class StubGenerateImageUseCase {}
final class StubDetectImageRequestUseCase {
    func execute(prompt: String) -> Single<Bool> { .just(false) }
}
final class StubFetchUserProfileUseCase {
    func execute() -> Single<UserProfile?> { .just(nil) }
}
final class StubFetchUserPreferenceUseCase {
    func execute() -> Single<UserPreference?> { .just(nil) }
}
final class StubUserPreferenceRepository: UserPreferenceRepository {
    func fetch(uid: String) -> Single<UserPreference?> { .just(nil) }
    func update(uid: String, items: [PreferenceItem]) -> Single<Void> { .just(()) }
}
final class StubAuthRepository: AuthRepository {
    var user: AuthUser? = AuthUser(uid: "u1", displayName: nil, photoURL: nil)
    func observeAuthState() -> Observable<AuthUser?> { .empty() }
    func currentUser() -> AuthUser? { user }
    func signOut() throws {}
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
            updatePreferenceUseCase: StubAnalyzeUserInputUseCase(),
            fetchPreferenceUseCase: StubFetchUserPreferenceUseCase(),
            fetchProfileUseCase: StubFetchUserProfileUseCase(),
            uploadFilesUseCase: StubUploadFilesUseCase(),
            generateImageUseCase: StubGenerateImageUseCase(),
            detectImageRequestUseCase: StubDetectImageRequestUseCase()
        )
        let now = Date().timeIntervalSince1970
        let events = [
            PreferenceEvent(key: "banana", relation: PreferenceRelation(rawValue: "like"), timestamp: now - 30),
            PreferenceEvent(key: "apple", relation: PreferenceRelation(rawValue: "avoid"), timestamp: now - 10),
            PreferenceEvent(key: "orange", relation: PreferenceRelation(rawValue: "want"), timestamp: now - 20),
            PreferenceEvent(key: "cake", relation: PreferenceRelation(rawValue: "like"), timestamp: now)
        ]
        let text = vm.preferenceText(from: events)
        XCTAssertEqual(text, "like: cake, avoid: apple, want: orange")
    }

    func test_profileText_builds_string() {
        let vm = ChatViewModel(
            sendMessageUseCase: StubSendChatWithContextUseCase(),
            summarizeUseCase: StubSummarizeMessagesUseCase(),
            saveConversationUseCase: StubSaveConversationUseCase(),
            appendMessageUseCase: StubAppendMessageUseCase(),
            fetchMessagesUseCase: StubFetchConversationMessagesUseCase(),
            contextRepository: StubChatContextRepository(),
            calculatePreferenceUseCase: StubCalculatePreferenceUseCase(),
            updatePreferenceUseCase: StubAnalyzeUserInputUseCase(),
            fetchPreferenceUseCase: StubFetchUserPreferenceUseCase(),
            fetchProfileUseCase: StubFetchUserProfileUseCase(),
            uploadFilesUseCase: StubUploadFilesUseCase(),
            generateImageUseCase: StubGenerateImageUseCase(),
            detectImageRequestUseCase: StubDetectImageRequestUseCase()
        )
        var profile = UserProfile()
        profile.age = 20
        profile.gender = "male"
        profile.job = "student"
        profile.interest = "game"
        let text = vm.profileText(from: profile)
        XCTAssertEqual(text, "age: 20, gender: male, job: student, interest: game")
    }
}
