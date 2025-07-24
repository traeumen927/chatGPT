import Foundation

final class GenerateImageUseCase {
    private let repository: OpenAIRepository

    init(repository: OpenAIRepository) {
        self.repository = repository
    }

    func execute(prompt: String, size: String, model: String, completion: @escaping (Result<[String], Error>) -> Void) {
        repository.generateImage(prompt: prompt, size: size, model: model, completion: completion)
    }
}
