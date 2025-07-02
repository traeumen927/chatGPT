import UIKit

final class TableBlockAttachment: NSTextAttachment {
    let rows: [[String]]
    let view: TableBlockView

    init(rows: [[String]]) {
        self.rows = rows
        self.view = TableBlockView(rows: rows)
        super.init(data: nil, ofType: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let targetWidth = lineFrag.width
        let size = view.systemLayoutSizeFitting(CGSize(width: targetWidth, height: .greatestFiniteMagnitude))
        return CGRect(origin: .zero, size: size)
    }
}
