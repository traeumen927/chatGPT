import UIKit
import SnapKit

final class TableBlockView: UIView {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let rows: [[String]]

    init(rows: [[String]]) {
        self.rows = rows
        super.init(frame: .zero)
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = false

        stackView.axis = .vertical
        stackView.spacing = 0

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        buildTable()
    }

    private func buildTable() {
        for (rowIndex, row) in rows.enumerated() {
            let container = UIView()
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 0

            for (index, cell) in row.enumerated() {
                let label = UILabel()
                label.font = .systemFont(ofSize: 14)
                label.numberOfLines = 0
                label.textAlignment = .center
                label.text = cell
                rowStack.addArrangedSubview(label)

                if index != row.count - 1 {
                    let vLine = UIView()
                    vLine.backgroundColor = .separator
                    rowStack.addArrangedSubview(vLine)
                    vLine.snp.makeConstraints { make in
                        make.width.equalTo(1.0 / UIScreen.main.scale)
                    }
                }
            }

            container.addSubview(rowStack)
            rowStack.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            if rowIndex != rows.count - 1 {
                let bottom = UIView()
                bottom.backgroundColor = .separator
                container.addSubview(bottom)
                bottom.snp.makeConstraints { make in
                    make.leading.trailing.bottom.equalToSuperview()
                    make.height.equalTo(1.0 / UIScreen.main.scale)
                }
            }

            stackView.addArrangedSubview(container)
        }
    }
}
