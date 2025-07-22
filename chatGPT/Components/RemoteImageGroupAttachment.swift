import UIKit

final class RemoteImageGroupAttachment: NSTextAttachment {
    let urls: [URL]
    let view: RemoteImageGroupView

    init(urls: [URL], style: RemoteImageGroupView.Style = .horizontal) {
        self.urls = urls
        self.view = RemoteImageGroupView(urls: urls, style: style)
        super.init(data: nil, ofType: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let width = lineFrag.width
        switch view.style {
        case .horizontal:
            return CGRect(x: 0, y: 0, width: width, height: width * 0.65)
        case .grid:
            let spacing: CGFloat = 8
            let itemWidth = (width - spacing * 2) / 3
            let rows = Int(ceil(Double(urls.count) / 3.0))
            let height = CGFloat(rows) * itemWidth + CGFloat(max(rows - 1, 0)) * spacing
            return CGRect(x: 0, y: 0, width: width, height: height)
        }
    }
}
