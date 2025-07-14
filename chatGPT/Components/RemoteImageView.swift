import UIKit
import SnapKit
import Kingfisher

final class RemoteImageView: UIView {
    private let imageView = UIImageView()
    private let url: URL

    init(url: URL) {
        self.url = url
        super.init(frame: .zero)
        layout()
        load()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.lessThanOrEqualTo(300).priority(999)
        }
    }

    private func load() {
        imageView.kf.setImage(with: url)
    }
}
