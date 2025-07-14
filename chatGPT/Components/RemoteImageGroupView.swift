import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class RemoteImageGroupView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let urls: [URL]
    private let disposeBag = DisposeBag()

    init(urls: [URL]) {
        self.urls = urls
        super.init(frame: .zero)
        layout()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        backgroundColor = ThemeColor.background1
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.showsHorizontalScrollIndicator = true
        stackView.axis = .horizontal
        stackView.spacing = 8

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let itemWidthRatio: CGFloat = 0.65
        urls.forEach { url in
            let imageView = RemoteImageView(url: url)
            stackView.addArrangedSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.width.equalTo(self.snp.width).multipliedBy(itemWidthRatio)
                make.height.equalTo(imageView.snp.width)
            }
        }
    }

    private func bind() {
        // nothing dynamic for now
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
}
