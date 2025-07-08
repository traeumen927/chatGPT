import Foundation
import RxSwift

protocol UserPreferenceRepository {
    func fetch(uid: String) -> Single<UserPreference?>
    func update(uid: String, items: [PreferenceItem]) -> Single<Void>
}
