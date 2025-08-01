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
        let analysis = openAIRepository.analyzeUserInput(prompt: prompt)
            .catch { error in
                if case OpenAIError.decodingError = error {
                    return .just(PreferenceAnalysisResult(info: UserInfo(attributes: [:])))
                }
                return .error(error)
            }
        let existing = infoRepository.fetch(uid: user.uid)
        let now = Date().timeIntervalSince1970
        return Single.zip(analysis, existing)
            .flatMap { [weak self] result, current -> Single<Void> in
                guard let self else { return .just(()) }
                var merged = current?.attributes ?? [:]
                for (key, facts) in result.info.attributes {
                    var arr = merged[key] ?? []
                    for fact in facts {
                        if let idx = arr.firstIndex(where: { $0.value == fact.value }) {
                            var old = arr[idx]
                            old.count += 1
                            old.lastMentioned = now
                            arr[idx] = old
                        } else {
                            var newFact = fact
                            newFact.firstMentioned = now
                            newFact.lastMentioned = now
                            arr.append(newFact)
                        }
                    }
                    merged[key] = arr
                }
                return self.infoRepository.update(uid: user.uid, attributes: merged)
            }
    }
}
