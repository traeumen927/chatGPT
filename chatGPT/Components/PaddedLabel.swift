import UIKit

final class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let adjusted = super.sizeThatFits(
            CGSize(width: size.width - textInsets.left - textInsets.right,
                   height: size.height - textInsets.top - textInsets.bottom))
        return CGSize(width: adjusted.width + textInsets.left + textInsets.right,
                      height: adjusted.height + textInsets.top + textInsets.bottom)
    }
}
