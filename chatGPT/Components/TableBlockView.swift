import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class TableBlockView: UIView {
    private let disposeBag = DisposeBag()
    private let stackView = UIStackView()
    private let copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        return button
    }()

    private let rows: [[String]]

    init(rows: [[String]]) {
        self.rows = rows
        super.init(frame: .zero)
        layout()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        backgroundColor = ThemeColor.background3
        layer.cornerRadius = 8

        addSubview(stackView)
        addSubview(copyButton)

        stackView.axis = .vertical
        stackView.spacing = 4

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        copyButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(8)
        }

        buildTable()
    }

    private func bind() {
        copyButton.rx.tap
            .bind { [weak self] in
                guard let self else { return }
                let text = self.rows.map { $0.joined(separator: "\t") }.joined(separator: "\n")
                UIPasteboard.general.string = text
            }
            .disposed(by: disposeBag)
    }

    private func buildTable() {
        rows.forEach { row in
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 4
            row.forEach { cell in
                let label = UILabel()
                label.font = .systemFont(ofSize: 14)
                label.numberOfLines = 0
                label.textAlignment = .center
                label.text = cell
                label.layer.borderWidth = 0.5
                label.layer.borderColor = UIColor.separator.cgColor
                rowStack.addArrangedSubview(label)
            }
            stackView.addArrangedSubview(rowStack)
        }
    }
}
