import UIKit
import SnapKit

final class TableBlockView: UIView {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let rows: [[String]]
    private var columnWidths: [CGFloat] = []
    private var mergedRows: Set<Int> = []
    private var verticalLines: [UIView] = []

    private let cellFont = UIFont.systemFont(ofSize: 14)
    private let cellInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
    private let mergeStartRow = 1

    init(rows: [[String]]) {
        self.rows = rows
        super.init(frame: .zero)
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 테이블 전체 구성의 루트 함수입니다.
    /// - scrollView, contentView, stackView의 계층 및 레이아웃을 정의하고,
    /// - 각 열의 너비 계산, 병합 행 탐지, 테이블 행 구성, 세로 구분선 배치를 포함합니다.
    private func layout() {
        // 스크롤 뷰 구성
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = false

        // 스택 뷰 구성
        stackView.axis = .vertical
        stackView.spacing = 0

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 열 너비 계산
        computeColumnWidths()
        let totalWidth = columnWidths.reduce(0, +)

        // 콘텐츠 뷰 크기 설정 (열 너비 총합 기반)
        contentView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
            make.width.equalTo(totalWidth + 1).priority(.required) // 여유 추가
            make.height.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 병합 대상 행 계산 및 테이블 구성
        computeMergedRows()
        buildTable()
        layoutVerticalLines()
    }

    private func layoutVerticalLines() {
        verticalLines.forEach { $0.removeFromSuperview() }
        verticalLines.removeAll()

        var offset: CGFloat = 0
        for (index, width) in columnWidths.enumerated() {
            offset += width
            guard index < columnWidths.count - 1 else { break }
            let line = UIView()
            line.backgroundColor = .separator
            contentView.addSubview(line)
            line.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.leading.equalToSuperview().offset(offset)
                make.width.equalTo(1.0 / UIScreen.main.scale)
            }
            verticalLines.append(line)
        }
    }

    /// 행(row) 단위로 테이블을 구성하는 핵심 함수입니다.
    /// 각 행은 UIStackView로 구성되며, 셀마다 UILabel 또는 UIView(병합된 셀 자리용 placeholder)를 배치합니다.
    /// `isMergedCell`로 판단하여 셀 병합 여부를 체크하고, 해당 셀이 병합되었으면 빈 UIView로 자리를 유지합니다.
    private func buildTable() {
        for (rowIndex, row) in rows.enumerated() {
            let container = UIView()
            let rowStack = UIStackView()
            rowStack.axis = .horizontal

            // 셀들의 고정된 width에 맞춰 비율에 따라 적절하게 공간을 분배함
            // 이 설정 덕분에 각 셀은 너비 고정 + 컨텐츠 기반 비율로 균형 있게 레이아웃됩니다.
            rowStack.distribution = .fillProportionally
            rowStack.spacing = 0

            var cells: [UIView] = []
            for (colIndex, cell) in row.enumerated() {
                // 병합 대상 셀인 경우 빈 UIView로 채워 열 너비 정렬 유지
                if isMergedCell(row: rowIndex, column: colIndex) {
                    let placeholder = UIView()
                    rowStack.addArrangedSubview(placeholder)
                    placeholder.snp.makeConstraints { make in
                        make.width.equalTo(columnWidths[colIndex])
                    }
                    cells.append(placeholder)
                    continue
                }

                // 일반 셀은 UILabel로 렌더링
                let label = PaddedLabel()
                label.textInsets = cellInsets
                label.font = cellFont
                label.numberOfLines = 1
                label.lineBreakMode = .byClipping
                label.textAlignment = .left
                label.text = cell
                label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                label.setContentHuggingPriority(.defaultHigh, for: .horizontal)

                rowStack.addArrangedSubview(label)

                // 셀의 너비를 명확히 고정하기 위해 columnWidths를 사용합니다.
                // 이 부분은 이후 동적 레이아웃을 위해 최소 너비 제약 등으로 개선될 여지가 있습니다.
                label.snp.makeConstraints { make in
                    make.width.equalTo(columnWidths[colIndex])
                }
                cells.append(label)
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
                if mergedRows.contains(rowIndex) {
                    bottom.isHidden = true
                }
            }

            stackView.addArrangedSubview(container)
        }
    }

    /// 각 열에서 가장 긴 문자열의 실제 렌더링 폭을 계산하여 columnWidths 배열에 저장합니다.
    /// - 셀 안의 마진 여유(cellInsets)와 추가 여백(16pt)을 더해 실제 셀 크기에 여유를 둡니다.
    private func computeColumnWidths() {
        guard let first = rows.first else { return }
        columnWidths = Array(repeating: 0, count: first.count)
        for row in rows {
            for (index, text) in row.enumerated() {
                let bounding = (text as NSString).size(withAttributes: [.font: cellFont]).width
                let value = bounding + cellInsets.left + cellInsets.right + 16 // cellInsets는 셀 안쪽 마진, 16은 여유 폭
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
