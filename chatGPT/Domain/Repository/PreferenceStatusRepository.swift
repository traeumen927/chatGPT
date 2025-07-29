import Foundation
import RxSwift

protocol PreferenceStatusRepository {
    func fetch(uid: String) -> Single<[PreferenceStatus]>
    func update(uid: String, status: PreferenceStatus) -> Single<Void>
    func delete(uid: String, key: String) -> Single<Void>
}
