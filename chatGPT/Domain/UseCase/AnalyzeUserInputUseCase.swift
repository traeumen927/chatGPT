import Foundation
import RxSwift

final class AnalyzeUserInputUseCase {
    private let openAIRepository: OpenAIRepository
    private let preferenceRepository: UserPreferenceRepository
    private let profileRepository: UserProfileRepository
    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init(openAIRepository: OpenAIRepository,
         preferenceRepository: UserPreferenceRepository,
         profileRepository: UserProfileRepository,
         getCurrentUserUseCase: GetCurrentUserUseCase) {
        self.openAIRepository = openAIRepository
        self.preferenceRepository = preferenceRepository
        self.profileRepository = profileRepository
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
            .do(onSuccess: { result in
                if result.preferences.isEmpty && result.profile == nil {
                    print(Strings.emptyResult)
                } else {
                    if !result.preferences.isEmpty {
                        let prefs = result.preferences
                            .map { "\($0.relation.rawValue): \($0.key)" }
                            .joined(separator: ", ")
                        print("Preferences ->", prefs)
                    }
                    if let profile = result.profile {
                        print("Profile ->", profile)
                    }
                }
            }, onError: { error in
                if (error as? OpenAIError) == .decodingError {
                    print(Strings.parseError)
                }
            })
            .catch { error in
                if case OpenAIError.decodingError = error {
                    return .just(PreferenceAnalysisResult(preferences: [], profile: nil))
                }
                return .error(error)
            }
            .flatMap { [weak self] result -> Single<Void> in
                guard let self else { return .just(()) }
                let now = Date().timeIntervalSince1970
                let items = result.preferences.map { pref in
                    PreferenceItem(key: pref.key,
                                   relation: pref.relation,
                                   updatedAt: now,
                                   count: 1)
                }
                let prefUpdate = self.preferenceRepository.update(uid: user.uid, items: items)
                let profileUpdate: Single<Void>
                if let profile = result.profile {
                    profileUpdate = self.profileRepository.update(uid: user.uid, profile: profile)
                } else {
                    profileUpdate = .just(())
                }
                return Single.zip(prefUpdate, profileUpdate).map { _ in }
            }
    }
}
