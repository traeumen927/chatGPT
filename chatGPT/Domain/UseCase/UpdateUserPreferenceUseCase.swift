import Foundation
import RxSwift

// 간단한 형태소 분석기를 사용해 토큰화합니다

final class UpdateUserPreferenceUseCase {
    private let repository: UserPreferenceRepository
    private let eventRepository: PreferenceEventRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let translationRepository: TranslationRepository
    private let statusRepository: PreferenceStatusRepository

    init(repository: UserPreferenceRepository,
         eventRepository: PreferenceEventRepository,
         statusRepository: PreferenceStatusRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase,
         translationRepository: TranslationRepository) {
        self.repository = repository
        self.eventRepository = eventRepository
        self.statusRepository = statusRepository
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
                return self.statusRepository.fetch(uid: user.uid)
                    .flatMap { [weak self] current -> Single<Void> in
                        guard let self else { return .just(()) }
                        var dict = Dictionary(uniqueKeysWithValues: current.map { ($0.key, $0) })
                        let statusUpdates = items.map { item -> PreferenceStatus in
                            let prev = dict[item.key]
                            var status = PreferenceStatus(key: item.key,
                                                          currentRelation: item.relation,
                                                          updatedAt: item.updatedAt,
                                                          previousRelation: nil,
                                                          changedAt: nil)
                            if let prev = prev, prev.currentRelation != item.relation {
                                status.previousRelation = prev.currentRelation
                                status.changedAt = item.updatedAt
                            }
                            dict[item.key] = status
                            return status
                        }
                        let updateSingles = statusUpdates.map {
                            self.statusRepository.update(uid: user.uid, status: $0)
                        }
                        let combined = Single.zip(updateSingles) { _ in }
                        return self.repository.update(uid: user.uid, items: items)
                            .flatMap { [weak self] _ -> Single<Void> in
                                guard let self else { return .just(()) }
                                return self.eventRepository.add(uid: user.uid, events: events)
                            }
                            .flatMap { combined }
                    }
            }
    }

    private func parse(prompt: String) -> [PreferenceItem] {
        let tokens = MorphTokenizer.tokenize(prompt)
        var items: [PreferenceItem] = []
        var index = 0
        func nextNoun(after idx: Int) -> (String, Int)? {
            var i = idx + 1
            while i < tokens.count {
                if tokens[i].isNoun {
                    return (tokens[i].text, i)
                }
                i += 1
            }
            return nil
        }

        while index < tokens.count {
            let token = tokens[index].text
            let time = Date().timeIntervalSince1970
            if token == "like" || token.hasPrefix("좋아"), let (key, i) = nextNoun(after: index) {
                items.append(PreferenceItem(key: key, relation: .like, updatedAt: time, count: 1))
                index = i
            } else if token == "dislike" || token.hasPrefix("싫어"), let (key, i) = nextNoun(after: index) {
                items.append(PreferenceItem(key: key, relation: .dislike, updatedAt: time, count: 1))
                index = i
            } else if token == "want" || token.hasPrefix("원") || token.contains("싶"), let (key, i) = nextNoun(after: index) {
                items.append(PreferenceItem(key: key, relation: .want, updatedAt: time, count: 1))
                index = i
            } else if token == "avoid" || token.hasPrefix("피하"), let (key, i) = nextNoun(after: index) {
                items.append(PreferenceItem(key: key, relation: .avoid, updatedAt: time, count: 1))
                index = i
            } else if tokens[index].isNoun, index + 1 < tokens.count {
                let next = tokens[index + 1].text
                if next == "like" || next.hasPrefix("좋아") {
                    items.append(PreferenceItem(key: token, relation: .like, updatedAt: time, count: 1))
                    index += 1
                } else if next == "dislike" || next.hasPrefix("싫어") {
                    items.append(PreferenceItem(key: token, relation: .dislike, updatedAt: time, count: 1))
                    index += 1
                } else if next == "want" || next.hasPrefix("원") || next.contains("싶") {
                    items.append(PreferenceItem(key: token, relation: .want, updatedAt: time, count: 1))
                    index += 1
                } else if next == "avoid" || next.hasPrefix("피하") {
                    items.append(PreferenceItem(key: token, relation: .avoid, updatedAt: time, count: 1))
                    index += 1
                }
            }
            index += 1
        }
        return items
    }
}
