import Foundation
import RxSwift

protocol UserProfileRepository {
    func fetch(uid: String) -> Single<UserProfile?>
    func update(uid: String, profile: UserProfile) -> Single<Void>
}
