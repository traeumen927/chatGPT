import UIKit
import SnapKit
import RxSwift
import RxCocoa
import QuickLook

final class DocumentViewerViewController: UIViewController {
    private let url: URL
    private let previewController = QLPreviewController()
    private let disposeBag = DisposeBag()
    private let bottomView = UIView()
    private let buttonStack = UIStackView()
    private let saveButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private var localURL: URL?

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout()
        bind()
        loadFile()
    }

    private func layout() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        addChild(previewController)
        view.addSubview(previewController.view)
        view.addSubview(bottomView)
        bottomView.addSubview(buttonStack)
        buttonStack.addArrangedSubview(saveButton)
        buttonStack.addArrangedSubview(shareButton)
        previewController.didMove(toParent: self)
        previewController.dataSource = self

        bottomView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually

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

        previewController.view.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomView.snp.top)
        }
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(64)
        }
        buttonStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bind() {
        saveButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .bind { [weak self] in self?.saveFile() }
            .disposed(by: disposeBag)

        shareButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .bind { [weak self] in self?.shareFile() }
            .disposed(by: disposeBag)
    }

    private func loadFile() {
        if url.isFileURL {
            localURL = url
            previewController.reloadData()
        } else {
            let task = URLSession.shared.downloadTask(with: url) { [weak self] temp, _, _ in
                guard let self, let temp else { return }
                self.localURL = temp
                DispatchQueue.main.async {
                    self.previewController.reloadData()
                }
            }
            task.resume()
        }
    }

    private func saveFile() {
        guard let localURL else { return }
        let picker = UIDocumentPickerViewController(forExporting: [localURL])
        present(picker, animated: true)
    }

    private func shareFile() {
        guard let localURL else { return }
        let activity = UIActivityViewController(activityItems: [localURL], applicationActivities: nil)
        present(activity, animated: true)
    }
}

extension DocumentViewerViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return localURL == nil ? 0 : 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return localURL! as NSURL
    }
}
