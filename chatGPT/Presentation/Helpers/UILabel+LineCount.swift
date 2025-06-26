import UIKit

extension UILabel {
    /// 현재 레이블이 표시하는 줄 수 계산
    var lineCount: Int {
        guard let text = self.text, let font = self.font else { return 0 }
        let maxWidth = preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : bounds.width
        let constraintRect = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect,
                                            options: [.usesLineFragmentOrigin, .usesFontLeading],
                                            attributes: [.font: font],
                                            context: nil)
        return Int(ceil(boundingBox.height / font.lineHeight))
    }
}
