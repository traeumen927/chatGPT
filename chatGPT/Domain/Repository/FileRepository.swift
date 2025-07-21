import Foundation
import RxSwift

protocol FileRepository {
    func uploadFiles(uid: String, datas: [Data]) -> Single<[URL]>
}
