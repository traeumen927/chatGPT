import UIKit
import SnapKit

import RxSwift
import RxCocoa

enum Attachment {
    case image(UIImage)
    case file(URL)
}

final class ChatComposerImageCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let closeButton = UIButton(type: .system)
    private var disposeBag = DisposeBag()

    var removeHandler: (() -> Void)?

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
        disposeBag = DisposeBag()
    }

    private func layout() {
        [imageView, closeButton].forEach(contentView.addSubview)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(imageView.snp.height)
        }

        let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = .black
        closeButton.layer.cornerRadius = 10
        closeButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(2)
            make.width.height.equalTo(20)
        }
    }

    func configure(attachment: Attachment, onDelete: @escaping () -> Void) {
        switch attachment {
        case .image(let image):
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
        case .file:
            imageView.image = UIImage(systemName: "doc.fill")
            imageView.contentMode = .scaleAspectFit
        }
        removeHandler = onDelete
        closeButton.rx.tap
            .bind { [weak self] in
                self?.removeHandler?()
            }
            .disposed(by: disposeBag)
    }
}
