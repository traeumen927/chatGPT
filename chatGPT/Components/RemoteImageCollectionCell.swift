import UIKit
import SnapKit

final class RemoteImageCollectionCell: UICollectionViewCell {
    private var imageView: RemoteImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        layout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.removeFromSuperview()
        imageView = nil
    }

    private func layout() {
        // nothing initially, added when configured
    }

    func configure(url: URL) {
        let view = RemoteImageView(url: url)
        contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(view.snp.height)
        }
        imageView = view
    }
}
