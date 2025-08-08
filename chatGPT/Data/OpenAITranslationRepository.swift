import Foundation
import RxSwift

final class OpenAITranslationRepository: TranslationRepository {
    private let repository: OpenAIRepository
    private let model: OpenAIModel

    init(repository: OpenAIRepository, model: OpenAIModel = OpenAIModel(id: "gpt-3.5-turbo")) {
        self.repository = repository
        self.model = model
    }

    func translateToEnglish(_ text: String) -> Single<String> {
        Single.create { single in
            let system = Message(role: .system, content: "Translate the following text to English. Respond only with the translated text.")
            let user = Message(role: .user, content: text)
            let token = self.repository.sendChat(messages: [system, user], model: self.model, stream: false) { result in
                switch result {
                case .success(let translated):
                    single(.success(translated.trimmingCharacters(in: .whitespacesAndNewlines)))
                case .failure(let error):
                    single(.failure(error))
                }
            }
            return Disposables.create { token.cancel() }
        }
    }
}
