import Foundation
import RxSwift

protocol UserInfoRepository {
    func fetch(uid: String) -> Single<UserInfo?>
    func update(uid: String, attributes: [String: [UserFact]]) -> Single<Void>
}
