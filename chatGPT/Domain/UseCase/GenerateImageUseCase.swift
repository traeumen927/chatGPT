import Foundation

final class GenerateImageUseCase {
    private let repository: OpenAIRepository

    init(repository: OpenAIRepository) {
        self.repository = repository
    }

    func execute(prompt: String, size: String, model: String, imageData: Data? = nil, completion: @escaping (Result<[String], Error>) -> Void) {
        if let data = imageData {
            repository.generateImageEdit(image: data, prompt: prompt, size: size, model: model, completion: completion)
        } else {
            repository.generateImage(prompt: prompt, size: size, model: model, completion: completion)
        }
    }
}
