import UIKit

protocol MarkdownRepository {
    func parse(_ markdown: String) -> NSAttributedString
}
