import UIKit

final class InlineCodeView: UILabel {
    private let padding = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)

    init(code: String) {
        super.init(frame: .zero)
        text = code
        font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textColor = ThemeColor.inlineCodeForeground
        backgroundColor = ThemeColor.inlineCodeBackground
        layer.cornerRadius = 4
        layer.masksToBounds = true
        numberOfLines = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + padding.left + padding.right,
                      height: size.height + padding.top + padding.bottom)
    }

    override func drawText(in rect: CGRect) {
        let insetRect = rect.inset(by: padding)
        super.drawText(in: insetRect)
    }
}
