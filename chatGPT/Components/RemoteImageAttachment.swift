import UIKit

final class RemoteImageAttachment: NSTextAttachment {
    let url: URL
    let altText: String
    let view: RemoteImageView

    init(url: URL, altText: String) {
        self.url = url
        self.altText = altText
        self.view = RemoteImageView(url: url)
        super.init(data: nil, ofType: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        CGRect(x: 0, y: 0, width: lineFrag.width, height: 200)
    }
}
