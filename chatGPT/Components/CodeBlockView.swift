import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CodeBlockView: UIView {
    private let disposeBag = DisposeBag()

    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.background2
        return view
    }()

    private let languageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = ThemeColor.label2
        return label
    }()

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = true
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceHorizontal = false
        view.alwaysBounceVertical = false
        view.bounces = false
        view.backgroundColor = .clear
        return view
    }()

    private let contentView: UIView = {
        let view = UIView()
        return view
    }()

    private let codeLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byClipping
        label.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        label.textColor = ThemeColor.label1
        return label
    }()

    private let copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        return button
    }()

    init(code: String, language: String? = nil) {
        super.init(frame: .zero)
        layout()
        bind()
        codeLabel.text = code
        languageLabel.text = language ?? "text"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        backgroundColor = ThemeColor.background3
        layer.cornerRadius = 8

        addSubview(headerView)
        addSubview(scrollView)
        headerView.addSubview(languageLabel)
        headerView.addSubview(copyButton)
        scrollView.addSubview(contentView)
        contentView.addSubview(codeLabel)

        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(24)
        }

        languageLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }

        copyButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.greaterThanOrEqualTo(scrollView.frameLayoutGuide.snp.width)
            make.height.equalTo(scrollView.frameLayoutGuide.snp.height)
        }

        codeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

    }

    private func bind() {
        copyButton.rx.tap
            .bind { [weak self] in
                guard let self else { return }
                UIPasteboard.general.string = self.codeLabel.text
            }
            .disposed(by: disposeBag)

        Observable
            .combineLatest(
                scrollView.rx.observe(CGSize.self, "contentSize"),
                scrollView.rx.observe(CGRect.self, "bounds")
            )
            .compactMap { contentSize, bounds -> Bool? in
                guard let contentSize, let bounds else { return nil }
                return contentSize.width > bounds.width
            }
            .distinctUntilChanged()
            .bind { [weak self] shouldBounce in
                self?.scrollView.alwaysBounceHorizontal = shouldBounce
                self?.scrollView.bounces = shouldBounce
            }
            .disposed(by: disposeBag)
    }
}
