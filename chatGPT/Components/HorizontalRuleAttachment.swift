import UIKit

final class HorizontalRuleAttachment: NSTextAttachment {
    let view: HorizontalRuleView

    override init(data: Data? = nil, ofType uti: String? = nil) {
        self.view = HorizontalRuleView()
        super.init(data: data, ofType: uti)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        CGRect(x: 0, y: 0, width: lineFrag.width, height: 1 / UIScreen.main.scale)
    }
}
