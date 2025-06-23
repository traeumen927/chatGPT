import UIKit
import RxSwift

protocol ImageRepository {
    func fetchImage(from url: URL) -> Single<UIImage>
}
