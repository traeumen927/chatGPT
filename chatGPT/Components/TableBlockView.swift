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
            make.top.bottom.leading.equalToSuperview()
            make.trailing.equalToSuperview().priority(.low)
            make.width.greaterThanOrEqualToSuperview()
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

            var cells: [UIView] = []
            for cell in row {
                let label = UILabel()
                label.font = .systemFont(ofSize: 14)
                label.numberOfLines = 0
                label.textAlignment = .center
                label.text = cell
                rowStack.addArrangedSubview(label)
                cells.append(label)
            }

            container.addSubview(rowStack)
            rowStack.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            for index in 0..<cells.count - 1 {
                let vLine = UIView()
                vLine.backgroundColor = .separator
                container.addSubview(vLine)
                vLine.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview()
                    make.leading.equalTo(cells[index].snp.trailing)
                    make.width.equalTo(1.0 / UIScreen.main.scale)
                }
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
