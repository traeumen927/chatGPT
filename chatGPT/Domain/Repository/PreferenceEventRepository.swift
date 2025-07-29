import Foundation
import RxSwift

protocol PreferenceEventRepository {
    func add(uid: String, events: [PreferenceEvent]) -> Single<Void>
    func fetch(uid: String) -> Single<[PreferenceEvent]>
    func delete(uid: String, eventID: String) -> Single<Void>
}
