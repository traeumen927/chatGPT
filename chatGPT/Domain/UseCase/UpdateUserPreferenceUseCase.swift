import Foundation
import RxSwift

final class UpdateUserPreferenceUseCase {
    private let repository: UserPreferenceRepository
    private let eventRepository: PreferenceEventRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let translationRepository: TranslationRepository

    init(repository: UserPreferenceRepository,
         eventRepository: PreferenceEventRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase,
         translationRepository: TranslationRepository) {
        self.repository = repository
        self.eventRepository = eventRepository
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.translationRepository = translationRepository
    }

    func execute(prompt: String) -> Single<Void> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(PreferenceError.noUser)
        }
        return translationRepository.translateToEnglish(prompt)
            .map { [weak self] in self?.parse(prompt: $0) ?? [] }
            .flatMap { [weak self] items -> Single<Void> in
                guard let self else { return .just(()) }
                let events = items.map { PreferenceEvent(key: $0.key,
                                                         relation: $0.relation,
                                                         timestamp: $0.updatedAt) }
                return self.repository.update(uid: user.uid, items: items)
                    .flatMap { [weak self] _ -> Single<Void> in
                        guard let self else { return .just(()) }
                        return self.eventRepository.add(uid: user.uid, events: events)
                    }
            }
    }

    private func parse(prompt: String) -> [PreferenceItem] {
        let tokens = prompt.lowercased().split { !$0.isLetter }
        var items: [PreferenceItem] = []
        var index = 0
        while index < tokens.count {
            let token = tokens[index]
            let time = Date().timeIntervalSince1970
            if token == "like", index + 1 < tokens.count {
                let key = String(tokens[index + 1])
                items.append(PreferenceItem(key: key, relation: .like, updatedAt: time, count: 1))
                index += 1
            } else if token == "dislike", index + 1 < tokens.count {
                let key = String(tokens[index + 1])
                items.append(PreferenceItem(key: key, relation: .dislike, updatedAt: time, count: 1))
                index += 1
            } else if token == "want", index + 1 < tokens.count {
                let key = String(tokens[index + 1])
                items.append(PreferenceItem(key: key, relation: .want, updatedAt: time, count: 1))
                index += 1
            } else if token == "avoid", index + 1 < tokens.count {
                let key = String(tokens[index + 1])
                items.append(PreferenceItem(key: key, relation: .avoid, updatedAt: time, count: 1))
                index += 1
            }
            index += 1
        }
        return items
    }
}
