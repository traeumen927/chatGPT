import Foundation
import RxSwift

final class AnalyzeUserInputUseCase {
    private let openAIRepository: OpenAIRepository
    private let infoRepository: UserInfoRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(openAIRepository: OpenAIRepository,
         infoRepository: UserInfoRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.openAIRepository = openAIRepository
        self.infoRepository = infoRepository
        self.getCurrentUserUseCase = getCurrentUserUseCase
    }

    private enum Strings {
        static let parseError = NSLocalizedString(
            "analyze_input_parse_error",
            comment: "Failed to parse analysis result"
        )
        static let emptyResult = NSLocalizedString(
            "analyze_input_empty",
            comment: "No preferences detected"
        )
    }

    func execute(prompt: String) -> Single<Void> {
        guard let user = getCurrentUserUseCase.execute() else {
            return .error(PreferenceError.noUser)
        }
        return openAIRepository.analyzeUserInput(prompt: prompt)
            .catch { error in
                if case OpenAIError.decodingError = error {
                    return .just(PreferenceAnalysisResult(info: UserInfo(attributes: [:])))
                }
                return .error(error)
            }
            .flatMap { [weak self] result -> Single<Void> in
                guard let self else { return .just(()) }
                return self.infoRepository.update(uid: user.uid,
                                                  attributes: result.info.attributes)
            }
    }
}
