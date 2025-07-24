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
    private var ratioConstraint: Constraint?

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
        backgroundColor = .clear
        layer.cornerRadius = 8
        clipsToBounds = true
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        snp.makeConstraints { make in
            ratioConstraint = make.height.equalTo(self.snp.width).constraint
        }
    }

    private func bind() {
        imageView.kf.indicatorType = .activity
        let placeholder = UIImage(systemName: "photo")
        let options: KingfisherOptionsInfo = [.transition(.fade(0.2))]
        imageView.backgroundColor = ThemeColor.background3
        imageView.kf.setImage(with: url, placeholder: placeholder, options: options) { [weak self] result in
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
