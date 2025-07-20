import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher

final class RemoteImageView: UIView {
    private let imageView = UIImageView()
    private let url: URL
    private let disposeBag = DisposeBag()
    private var loadedImage: UIImage?

    init(url: URL) {
        self.url = url
        super.init(frame: .zero)
        layout()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        backgroundColor = ThemeColor.background2
        layer.cornerRadius = 8
        clipsToBounds = true
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bind() {
        imageView.kf.setImage(with: url) { [weak self] result in
            if case .success(let value) = result {
                self?.loadedImage = value.image
            }
        }
        
        let tapGesture = UITapGestureRecognizer()
                imageView.addGestureRecognizer(tapGesture)

                tapGesture.rx.event
                    .compactMap { [weak self] _ in self?.loadedImage }
                    .bind { image in
                        let viewer = ImageViewerViewController(image: image)
                        viewer.modalPresentationStyle = .overFullScreen
                        viewer.modalTransitionStyle = .crossDissolve
                        UIApplication.topViewController?.present(viewer, animated: true)
                    }
                    .disposed(by: disposeBag)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
}
