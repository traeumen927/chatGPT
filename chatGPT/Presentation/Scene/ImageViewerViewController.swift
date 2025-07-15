import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ImageViewerViewController: UIViewController {
    private let image: UIImage
    private let disposeBag = DisposeBag()

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout()
        bind()
    }

    private func layout() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self

        view.addSubview(scrollView)
        scrollView.addSubview(imageView)

        imageView.contentMode = .scaleAspectFit
        imageView.image = image

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

    private func bind() {
        let tapGesture = UITapGestureRecognizer()
        view.addGestureRecognizer(tapGesture)

        tapGesture.rx.event
            .bind { [weak self] _ in
                self?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}

extension ImageViewerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
