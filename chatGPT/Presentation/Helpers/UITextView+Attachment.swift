import UIKit

extension UITextView {
    func addAttachmentViews() {
        subviews.forEach { view in
            if view is CodeBlockView || view is HorizontalRuleView || view is TableBlockView || view is RemoteImageView || view is RemoteImageGroupView {
                view.removeFromSuperview()
            }
        }

        guard let attributed = attributedText else { return }
        let fullRange = NSRange(location: 0, length: attributed.length)
        attributed.enumerateAttribute(.attachment, in: fullRange) { value, range, _ in
            if let attachment = value as? CodeBlockAttachment {
                let rect = self.boundingRect(forCharacterRange: range)
                guard !rect.isNull, !rect.isInfinite, !rect.isEmpty else { return }
                attachment.view.frame = rect
                addSubview(attachment.view)
            } else if let attachment = value as? HorizontalRuleAttachment {
                let rect = self.boundingRect(forCharacterRange: range)
                guard !rect.isNull, !rect.isInfinite, !rect.isEmpty else { return }
                attachment.view.frame = rect
                addSubview(attachment.view)
            } else if let attachment = value as? TableBlockAttachment {
                let rect = self.boundingRect(forCharacterRange: range)
                guard !rect.isNull, !rect.isInfinite, !rect.isEmpty else { return }
                attachment.view.frame = rect
                addSubview(attachment.view)
            } else if let attachment = value as? RemoteImageAttachment {
                let rect = self.boundingRect(forCharacterRange: range)
                guard !rect.isNull, !rect.isInfinite, !rect.isEmpty else { return }
                attachment.view.frame = rect
                addSubview(attachment.view)
            } else if let attachment = value as? RemoteImageGroupAttachment {
                let rect = self.boundingRect(forCharacterRange: range)
                guard !rect.isNull, !rect.isInfinite, !rect.isEmpty else { return }
                attachment.view.frame = rect
                addSubview(attachment.view)
            }
        }
    }

    private func boundingRect(forCharacterRange range: NSRange) -> CGRect {
        guard let start = position(from: beginningOfDocument, offset: range.location),
              let end = position(from: beginningOfDocument, offset: range.location + range.length),
              let textRange = textRange(from: start, to: end) else {
            return .zero
        }
        let rect = firstRect(for: textRange).integral
        let padding = textContainerInset.left + textContainer.lineFragmentPadding
        let width = bounds.width - padding * 2
        return CGRect(x: padding, y: rect.minY, width: width, height: rect.height)
    }
}
