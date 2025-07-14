import UIKit

final class RemoteImageGroupAttachment: NSTextAttachment {
    let urls: [URL]
    let view: RemoteImageGroupView

    init(urls: [URL]) {
        self.urls = urls
        self.view = RemoteImageGroupView(urls: urls)
        super.init(data: nil, ofType: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        CGRect(x: 0, y: 0, width: lineFrag.width, height: lineFrag.width * 0.65)
    }
}
