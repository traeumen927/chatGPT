import UIKit

extension UITextView {
    func addAttachmentViews() {
        subviews.forEach { view in
            if view is CodeBlockView { view.removeFromSuperview() }
        }

        guard let attributed = attributedText else { return }
        let fullRange = NSRange(location: 0, length: attributed.length)
        attributed.enumerateAttribute(.attachment, in: fullRange) { value, range, _ in
            guard let attachment = value as? CodeBlockAttachment else { return }
            let rect = self.boundingRect(forCharacterRange: range)
            guard !rect.isNull, !rect.isInfinite, !rect.isEmpty else { return }
            attachment.view.frame = rect
            addSubview(attachment.view)
        }
    }

    private func boundingRect(forCharacterRange range: NSRange) -> CGRect {
        guard let start = position(from: beginningOfDocument, offset: range.location),
              let end = position(from: beginningOfDocument, offset: range.location + range.length),
              let textRange = textRange(from: start, to: end) else {
            return .zero
        }
        let rect = firstRect(for: textRange)
        return rect.integral
    }
}
