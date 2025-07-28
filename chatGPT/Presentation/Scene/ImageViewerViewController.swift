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
import Toast
import AVFoundation

final class ImageViewerViewController: UIViewController {
    private let image: UIImage
    private let disposeBag = DisposeBag()

    private let scrollView = UIScrollView()
    private let checkerboardView = CheckerboardView()
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let rect = AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds)
        checkerboardView.frame = imageView.convert(rect, to: scrollView)
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
        scrollView.addSubview(checkerboardView)
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
        var saveTitle = AttributedString("저장")
        saveTitle.font = .systemFont(ofSize: 10)
        saveConfig.attributedTitle = saveTitle
        saveButton.configuration = saveConfig

        var shareConfig = UIButton.Configuration.plain()
        shareConfig.image = UIImage(systemName: "square.and.arrow.up")
        shareConfig.imagePlacement = .top
        shareConfig.imagePadding = 4
        var shareTitle = AttributedString("공유")
        shareTitle.font = .systemFont(ofSize: 10)
        shareConfig.attributedTitle = shareTitle
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
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
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
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc
    private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        guard error == nil else { return }
        view.makeToast("저장이 완료되었습니다", duration: 1.5, position: .bottom)
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
