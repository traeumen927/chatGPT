import UIKit
import RxSwift
import Kingfisher

final class KingfisherImageRepository: ImageRepository {
    func fetchImage(from url: URL) -> Single<UIImage> {
        Single.create { single in
            let task = KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case .success(let value):
                    single(.success(value.image))
                case .failure(let error):
                    single(.failure(error))
                }
            }
            return Disposables.create { task?.cancel() }
        }
    }
}
