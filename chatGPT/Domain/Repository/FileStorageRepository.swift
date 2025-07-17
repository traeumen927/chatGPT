import Foundation
import RxSwift

protocol FileStorageRepository {
    func upload(data: Data, path: String) -> Single<URL>
}
