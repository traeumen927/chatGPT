//
//  LinkLabel.swift
//  chatGPT
//
//  Created by 홍정연 on 6/12/25.
//

import UIKit

// MARK: 링크 할당이 가능한 라벨
import UIKit

class LinkLabel: UILabel {
    
    private var linkRange: NSRange?
    private var linkURL: URL?

    // 커스터마이징 가능한 속성
    var linkTextColor: UIColor = .systemBlue
    var linkUnderlineColor: UIColor? = nil  // nil이면 기본값 사용

    // MARK: 초기화
    override init(frame: CGRect) {
        super.init(frame: frame)
        layout()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layout()
    }

    private func layout() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
    }

    // 텍스트 설정 + 링크 적용
    func setTextWithLink(fullText: String, linkText: String, linkURL: URL) {
        let attributed = NSMutableAttributedString(string: fullText)

        if let range = fullText.range(of: linkText) {
            let nsRange = NSRange(range, in: fullText)
            self.linkRange = nsRange
            self.linkURL = linkURL

            attributed.addAttribute(.foregroundColor, value: linkTextColor, range: nsRange)
            attributed.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)

            if let underlineColor = linkUnderlineColor {
                attributed.addAttribute(.underlineColor, value: underlineColor, range: nsRange)
            }
        }

        self.attributedText = attributed
    }

    // 터치 감지 → 링크 영역일 경우 Safari 열기
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let attrText = self.attributedText,
              let linkRange = self.linkRange,
              let url = self.linkURL else { return }

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: bounds.size)
        let textStorage = NSTextStorage(attributedString: attrText)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode

        let location = gesture.location(in: self)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let offset = CGPoint(x: (bounds.size.width - textBoundingBox.size.width) / 2 - textBoundingBox.origin.x,
                             y: (bounds.size.height - textBoundingBox.size.height) / 2 - textBoundingBox.origin.y)
        let touchPoint = CGPoint(x: location.x - offset.x, y: location.y - offset.y)

        let index = layoutManager.characterIndex(for: touchPoint, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        if NSLocationInRange(index, linkRange) {
            UIApplication.shared.open(url)
        }
    }
}


