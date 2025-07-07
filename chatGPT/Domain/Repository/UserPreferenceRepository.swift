import Foundation
import RxSwift

protocol UserPreferenceRepository {
    func fetch(uid: String) -> Single<UserPreference?>
    func update(uid: String, tokens: [String]) -> Single<Void>
}
