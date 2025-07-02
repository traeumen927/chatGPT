import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CodeBlockView: UIView {
    private let disposeBag = DisposeBag()

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = true
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceHorizontal = true
        view.alwaysBounceVertical = false
        view.bounces = true
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
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        return button
    }()

    init(code: String) {
        super.init(frame: .zero)
        layout()
        bind()
        codeLabel.text = code
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        backgroundColor = ThemeColor.background3
        layer.cornerRadius = 8

        addSubview(scrollView)
        addSubview(copyButton)
        scrollView.addSubview(contentView)
        contentView.addSubview(codeLabel)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        contentView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.trailing.equalToSuperview().priority(.low)
            make.width.greaterThanOrEqualToSuperview()
            make.height.equalToSuperview()
        }

        codeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        copyButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().inset(8)
        }
    }

    private func bind() {
        copyButton.rx.tap
            .bind { [weak self] in
                guard let self else { return }
                UIPasteboard.general.string = self.codeLabel.text
            }
            .disposed(by: disposeBag)
    }
}
