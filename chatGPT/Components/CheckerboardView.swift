import UIKit
import SnapKit

final class CheckerboardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        layout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layout()
    }

    private func layout() {
        backgroundColor = UIColor(patternImage: Self.patternImage)
        isUserInteractionEnabled = false
    }

    private static var patternImage: UIImage {
        let tileSize: CGFloat = 8
        let size = CGSize(width: tileSize * 2, height: tileSize * 2)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor(white: 0.9, alpha: 1.0).setFill()
            context.fill(CGRect(x: 0, y: 0, width: tileSize, height: tileSize))
            context.fill(CGRect(x: tileSize, y: tileSize, width: tileSize, height: tileSize))
        }
    }
}
