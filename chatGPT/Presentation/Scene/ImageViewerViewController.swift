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
    private let bottomView = UIView()
    private let buttonStack = UIStackView()
    private let saveButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)

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
        view.addSubview(bottomView)
        headerView.addSubview(closeButton)
        bottomView.addSubview(buttonStack)
        buttonStack.addArrangedSubview(saveButton)
        buttonStack.addArrangedSubview(shareButton)
        scrollView.addSubview(imageView)

        imageView.contentMode = .scaleAspectFit
        imageView.image = image

        headerView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        bottomView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white

        var saveConfig = UIButton.Configuration.plain()
        saveConfig.image = UIImage(systemName: "square.and.arrow.down")
        saveConfig.imagePlacement = .top
        saveConfig.imagePadding = 4
        saveConfig.title = "저장"
        saveButton.configuration = saveConfig

        var shareConfig = UIButton.Configuration.plain()
        shareConfig.image = UIImage(systemName: "square.and.arrow.up")
        shareConfig.imagePlacement = .top
        shareConfig.imagePadding = 4
        shareConfig.title = "공유"
        shareButton.configuration = shareConfig

        [saveButton, shareButton].forEach { $0.tintColor = .white }

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

        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(64)
        }
        buttonStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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

        saveButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .bind { [weak self] in
                self?.saveImage()
            }
            .disposed(by: disposeBag)

        shareButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .bind { [weak self] in
                self?.shareImage()
            }
            .disposed(by: disposeBag)
    }

    private func saveImage() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    private func shareImage() {
        let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activity, animated: true)
    }
}

extension ImageViewerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
