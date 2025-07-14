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
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.lessThanOrEqualTo(300).priority(999)
        }
    }

    private func bind() {
        print("url: \(url)")
        imageRepository.fetchImage(from: url)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] image in
                self?.imageView.image = image
            })
            .disposed(by: disposeBag)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 200)
    }
}
