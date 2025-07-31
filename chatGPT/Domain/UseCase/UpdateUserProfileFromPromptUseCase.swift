import Foundation
import RxSwift

final class UpdateUserProfileFromPromptUseCase {
    private let fetchUseCase: FetchUserProfileUseCase
    private let updateUseCase: UpdateUserProfileUseCase
    private let translationRepository: TranslationRepository

    init(fetchUseCase: FetchUserProfileUseCase,
         updateUseCase: UpdateUserProfileUseCase,
         translationRepository: TranslationRepository) {
        self.fetchUseCase = fetchUseCase
        self.updateUseCase = updateUseCase
        self.translationRepository = translationRepository
    }

    func execute(prompt: String) -> Single<UserProfile> {
        fetchUseCase.execute()
            .catchAndReturn(nil)
            .flatMap { [weak self] current -> Single<UserProfile> in
                guard let self else { return .just(current ?? UserProfile()) }
                return self.translationRepository.translateToEnglish(prompt)
                    .map { [weak self] in
                        self?.parse(text: $0, base: current ?? UserProfile()) ?? UserProfile()
                    }
            }
            .flatMap { [weak self] profile in
                guard let self else { return .just(profile) }
                return self.updateUseCase.execute(profile: profile).map { profile }
            }
    }

    private func parse(text: String, base: UserProfile) -> UserProfile {
        var profile = base
        let lower = text.lowercased()
        if let age = self.match(text: lower, pattern: "i am (\\d{1,3}) years old"), let num = Int(age) {
            profile.age = num
        }
        if lower.contains("i am male") || lower.contains("i'm male") {
            profile.gender = "male"
        } else if lower.contains("i am female") || lower.contains("i'm female") {
            profile.gender = "female"
        }
        if let job = self.match(text: lower, pattern: "my job is ([a-z ]+)") {
            profile.job = job.trimmingCharacters(in: .whitespaces)
        } else if let job = self.match(text: lower, pattern: "i work as ([a-z ]+)") {
            profile.job = job.trimmingCharacters(in: .whitespaces)
        }
        if let interest = self.match(text: lower, pattern: "i am interested in ([a-z ]+)") {
            profile.interest = interest.trimmingCharacters(in: .whitespaces)
        }
        return profile
    }

    private func match(text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }
}
