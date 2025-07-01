import UIKit

final class InlineCodeAttachment: NSTextAttachment {
    let code: String
    let view: InlineCodeView

    init(code: String) {
        self.code = code
        self.view = InlineCodeView(code: code)
        super.init(data: nil, ofType: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGRect(origin: .zero, size: size)
    }
}
