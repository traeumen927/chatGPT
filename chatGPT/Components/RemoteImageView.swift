import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class RemoteImageView: UIView {
    private let imageView = UIImageView()
    private let url: URL
    private let disposeBag = DisposeBag()
    private let imageRepository = KingfisherImageRepository()

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
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bind() {
        imageRepository.fetchImage(from: url)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] image in
                self?.imageView.image = image
            })
            .disposed(by: disposeBag)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 200, height: 200)
    }
}
