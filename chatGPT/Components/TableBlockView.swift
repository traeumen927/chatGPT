import UIKit
import SnapKit

final class TableBlockView: UIView {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let rows: [[String]]
    private var columnWidths: [CGFloat] = []
    private var mergedRows: Set<Int> = []

    private let cellFont = UIFont.systemFont(ofSize: 14)
    private let cellInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    private let mergeStartRow = 1

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
            make.height.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        computeColumnWidths()
        computeMergedRows()
        buildTable()
    }

    private func buildTable() {
        for (rowIndex, row) in rows.enumerated() {
            let container = UIView()
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fill
            rowStack.spacing = 0

            var cells: [UIView] = []
            for (colIndex, cell) in row.enumerated() {
                if isMergedCell(row: rowIndex, column: colIndex) {
                    let placeholder = UIView()
                    rowStack.addArrangedSubview(placeholder)
                    placeholder.snp.makeConstraints { make in
                        make.width.equalTo(columnWidths[colIndex])
                    }
                    cells.append(placeholder)
                    continue
                }

                let label = PaddedLabel()
                label.textInsets = cellInsets
                label.font = cellFont
                label.numberOfLines = 0
                label.textAlignment = .left
                label.text = cell
                rowStack.addArrangedSubview(label)
                label.snp.makeConstraints { make in
                    make.width.equalTo(columnWidths[colIndex])
                }
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
                if isMergedCell(row: rowIndex, column: index) ||
                    isMergedCell(row: rowIndex, column: index + 1) {
                    vLine.isHidden = true
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
                if mergedRows.contains(rowIndex) {
                    bottom.isHidden = true
                }
            }

            stackView.addArrangedSubview(container)
        }
    }

    private func computeColumnWidths() {
        guard let first = rows.first else { return }
        columnWidths = Array(repeating: 0, count: first.count)
        for row in rows {
            for (index, text) in row.enumerated() {
                let width = (text as NSString).size(withAttributes: [.font: cellFont]).width
                let value = width + cellInsets.left + cellInsets.right
                if value > columnWidths[index] {
                    columnWidths[index] = value
                }
            }
        }
    }

    private func computeMergedRows() {
        guard !rows.isEmpty else { return }
        let columnCount = rows[0].count
        for col in 0..<columnCount {
            var row = mergeStartRow - 1
            while row < rows.count {
                row += 1
                guard row < rows.count else { break }
                if rows[row][col].isEmpty { continue }
                var next = row + 1
                while next < rows.count && rows[next][col].isEmpty {
                    mergedRows.insert(next - 1)
                    next += 1
                }
                row = next - 1
            }
        }
    }

    private func isMergedCell(row: Int, column: Int) -> Bool {
        guard row > mergeStartRow else { return false }
        if rows[row][column].isEmpty && mergedRows.contains(row - 1) {
            return true
        }
        return false
    }
}
