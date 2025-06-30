import UIKit

final class ParseMarkdownUseCase {
    private let repository: MarkdownRepository

    init(repository: MarkdownRepository) {
        self.repository = repository
    }

    func execute(markdown: String) -> NSAttributedString {
        repository.parse(markdown)
    }
}
