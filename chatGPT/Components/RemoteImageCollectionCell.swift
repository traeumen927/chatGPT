import UIKit
import SnapKit

final class RemoteImageCollectionCell: UICollectionViewCell {
    private var imageView: RemoteImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.removeFromSuperview()
        imageView = nil
    }

    func configure(url: URL) {
        let view = RemoteImageView(url: url)
        contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        imageView = view
    }
}
