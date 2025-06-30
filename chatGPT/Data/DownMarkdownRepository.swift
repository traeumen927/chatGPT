import UIKit
import Down

final class DownMarkdownRepository: MarkdownRepository {
    func parse(_ markdown: String) -> NSAttributedString {
        if let attributed = try? Down(markdownString: markdown).toAttributedString() {
            return attributed
        }
        return NSAttributedString(string: markdown)
    }
}
