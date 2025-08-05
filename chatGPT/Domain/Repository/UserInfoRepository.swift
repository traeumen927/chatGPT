import Foundation
import RxSwift

protocol UserInfoRepository {
    func fetch(uid: String) -> Single<UserInfo?>
    func observe(uid: String, since: TimeInterval?) -> Observable<UserInfo?>
    func update(uid: String, attributes: [String: [UserFact]]) -> Single<Void>
}
