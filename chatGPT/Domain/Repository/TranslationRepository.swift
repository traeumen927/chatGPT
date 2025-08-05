import Foundation
import RxSwift

protocol TranslationRepository {
    func translateToEnglish(_ text: String) -> Single<String>
}
