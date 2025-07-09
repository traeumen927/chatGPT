import UIKit

final class CodeBlockAttachment: NSTextAttachment {
    let code: String
    let language: String?
    let view: CodeBlockView

    init(code: String, language: String? = nil) {
        self.code = code
        self.language = language
        self.view = CodeBlockView(code: code, language: language)
        super.init(data: nil, ofType: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let targetWidth = lineFrag.width
        var size = view.systemLayoutSizeFitting(CGSize(width: targetWidth, height: .greatestFiniteMagnitude))
        size.width = max(size.width, targetWidth)
        return CGRect(origin: .zero, size: size)
    }
}
