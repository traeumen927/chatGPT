import UIKit

final class TrailingFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard
            let attributes = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }),
            let collectionView = collectionView
        else { return super.layoutAttributesForElements(in: rect) }

        var rows: [[UICollectionViewLayoutAttributes]] = []
        var currentRow: [UICollectionViewLayoutAttributes] = []
        var currentY: CGFloat = -1

        for attr in attributes where attr.representedElementCategory == .cell {
            if currentY == -1 || abs(attr.frame.minY - currentY) > 1e-5 {
                if !currentRow.isEmpty { rows.append(currentRow) }
                currentRow = [attr]
                currentY = attr.frame.minY
            } else {
                currentRow.append(attr)
            }
        }
        if !currentRow.isEmpty { rows.append(currentRow) }

        let availableWidth = collectionView.bounds.width - sectionInset.left - sectionInset.right

        for row in rows {
            let rowWidth = row.reduce(0) { $0 + $1.frame.width } + minimumInteritemSpacing * CGFloat(max(0, row.count - 1))
            guard rowWidth < availableWidth else { continue }
            let offset = availableWidth - rowWidth
            for attr in row { attr.frame.origin.x += offset }
        }

        return attributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }
}
