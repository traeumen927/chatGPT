import UIKit
import SnapKit

final class RemoteImageCell: UICollectionViewCell {
    private var imageView: RemoteImageView?

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
