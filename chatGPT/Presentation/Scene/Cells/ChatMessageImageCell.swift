import UIKit
import SnapKit

final class ChatMessageImageCell: UICollectionViewCell {
    private var imageView: RemoteImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(url: URL) {
        imageView?.removeFromSuperview()
        let view = RemoteImageView(url: url)
        contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        imageView = view
    }
}
