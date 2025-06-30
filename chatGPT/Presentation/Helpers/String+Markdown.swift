import UIKit

extension String {
    func markdownAttributed(font: UIFont, textColor: UIColor) -> NSAttributedString {
        if #available(iOS 15.0, *) {
            do {
                var attr = try AttributedString(markdown: self)
                var container = AttributeContainer()
                container.font = font
                container.foregroundColor = textColor
                attr = attr.mergingAttributes(container)
                return NSAttributedString(attr)
            } catch {
                return NSAttributedString(string: self, attributes: [
                    .font: font,
                    .foregroundColor: textColor
                ])
            }
        } else {
            return NSAttributedString(string: self, attributes: [
                .font: font,
                .foregroundColor: textColor
            ])
        }
    }
}
