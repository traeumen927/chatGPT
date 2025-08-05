import Foundation
import RxSwift
import RxRelay

final class UserMemoryStore {
    static let shared = UserMemoryStore()
    private let relay = BehaviorRelay<UserInfo?>(value: nil)
    private let disposeBag = DisposeBag()
    private let ttl: TimeInterval = 60 * 60 * 24 * 365 // 1 year

    var info: UserInfo? { relay.value }
    var latestTimestamp: TimeInterval? {
        info?.attributes.values
            .flatMap { $0 }
            .map { $0.lastMentioned }
            .max()
    }

    func bind(_ observable: Observable<UserInfo?>) {
        observable
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] info in
                self?.update(info)
            })
            .disposed(by: disposeBag)
    }

    func asObservable() -> Observable<UserInfo?> {
        relay.asObservable()
    }

    private func update(_ info: UserInfo) {
        let now = Date().timeIntervalSince1970
        var filtered: [String: [UserFact]] = [:]
        for (key, facts) in info.attributes {
            let valid = facts.filter { now - $0.lastMentioned < ttl }
            if !valid.isEmpty {
                filtered[key] = valid
            }
        }
        relay.accept(UserInfo(attributes: filtered))
    }
}
