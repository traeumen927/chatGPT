import Foundation
import RxSwift

final class CalculatePreferenceUseCase {
    private let eventRepository: PreferenceEventRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let decay: Double

    init(eventRepository: PreferenceEventRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase,
         decay: Double = 0.001) {
        self.eventRepository = eventRepository
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.decay = decay
    }

    func execute(top: Int) -> Single<[PreferenceEvent]> {
        guard let user = getCurrentUserUseCase.execute() else { return .just([]) }
        return eventRepository.fetch(uid: user.uid)
            .map { [decay] events in
                let now = Date().timeIntervalSince1970
                var scores: [String: Double] = [:]
                events.forEach { ev in
                    let key = "\(ev.relation.rawValue):\(ev.key)"
                    let weight = exp(-decay * (now - ev.timestamp))
                    scores[key, default: 0] += weight
                }
                let sorted = scores.sorted { $0.value > $1.value }.prefix(top)
                return sorted.map { entry in
                    let comps = entry.key.split(separator: ":", maxSplits: 1)
                    let relation = PreferenceRelation(rawValue: String(comps[0]))!
                    let key = String(comps[1])
                    return PreferenceEvent(key: key, relation: relation, timestamp: now)
                }
            }
    }
}
