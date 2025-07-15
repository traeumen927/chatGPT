//
//  ImageViewerViewController.swift
//  chatGPT
//
//  Created by 홍정연 on 7/15/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ImageViewerViewController: UIViewController {
    private let image: UIImage
    private let disposeBag = DisposeBag()

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let headerView = UIView()
    private let closeButton = UIButton(type: .system)

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
        view.backgroundColor = UIColor.black.withAlphaComponent(0.95)

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self

        view.addSubview(scrollView)
        view.addSubview(headerView)
        headerView.addSubview(closeButton)
        scrollView.addSubview(imageView)

        imageView.contentMode = .scaleAspectFit
        imageView.image = image

        headerView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(44)
        }

        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

    private func bind() {
        closeButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .bind { [weak self] in
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
