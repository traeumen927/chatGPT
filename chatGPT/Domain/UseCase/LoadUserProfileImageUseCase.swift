import UIKit
import RxSwift

final class LoadUserProfileImageUseCase {
    private let imageRepository: ImageRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(imageRepository: ImageRepository, getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.imageRepository = imageRepository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    func execute() -> Single<UIImage> {
        guard let user = getCurrentUserUseCase.execute(), let url = user.photoURL else {
            return .error(ImageError.missingURL)
        }
        return imageRepository.fetchImage(from: url)
    }
}

enum ImageError: Error {
    case missingURL
}
