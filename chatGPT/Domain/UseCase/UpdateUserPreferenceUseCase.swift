import Foundation
import RxSwift

final class UpdateUserPreferenceUseCase {
    private let repository: UserPreferenceRepository
    private let eventRepository: PreferenceEventRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let tokenizer = KoreanTokenizer()

    init(repository: UserPreferenceRepository,
         eventRepository: PreferenceEventRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.repository = repository
        self.eventRepository = eventRepository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute(prompt: String) -> Single<Void> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(PreferenceError.noUser)
        }
        let items = self.parse(prompt: prompt)
        let events = items.map { PreferenceEvent(key: $0.key,
                                                 relation: $0.relation,
                                                 timestamp: $0.updatedAt) }
        return repository.update(uid: user.uid, items: items)
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self else { return .just(()) }
                return self.eventRepository.add(uid: user.uid, events: events)
            }
    }

    private func parse(prompt: String) -> [PreferenceItem] {
        let tokens = tokenizer.nouns(from: prompt)
        var items: [PreferenceItem] = []
        for (index, token) in tokens.enumerated() {
            let time = Date().timeIntervalSince1970
            if token.contains("좋아") && index > 0 {
                let key = tokens[index - 1]
                let item = PreferenceItem(key: key, relation: .like, updatedAt: time, count: 1)
                items.append(item)
            } else if token.contains("싫어") && index > 0 {
                let key = tokens[index - 1]
                let item = PreferenceItem(key: key, relation: .dislike, updatedAt: time, count: 1)
                items.append(item)
            } else if (token.contains("원해") || token.contains("해줘")) && index > 0 {
                let key = tokens[index - 1]
                let item = PreferenceItem(key: key, relation: .want, updatedAt: time, count: 1)
                items.append(item)
            } else if (token.contains("원하지") || token.contains("하지마")) && index > 0 {
                let key = tokens[index - 1]
                let item = PreferenceItem(key: key, relation: .avoid, updatedAt: time, count: 1)
                items.append(item)
            }
        }
        return items
    }
}
