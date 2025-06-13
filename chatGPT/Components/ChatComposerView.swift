//
//  ChatComposerView.swift
//  chatGPT
//
//  Created by 홍정연 on 6/13/25.
//

import UIKit
import SnapKit

final class ChatComposerView: UIView, UITextViewDelegate {

    // MARK: - UI
    private let textView = UITextView()
    private let placeholderLabel = UILabel()

    // MARK: - Constraints
    private var textViewHeightConstraint: Constraint?

    // MARK: - Configurable Constants
    private var lineHeight: CGFloat {
        return textView.font?.lineHeight ?? UIFont.systemFont(ofSize: 14).lineHeight
    }

    private var minTextViewHeight: CGFloat {
        let insets = textView.textContainerInset.top + textView.textContainerInset.bottom
        return lineHeight + insets
    }

    private var maxTextViewHeight: CGFloat {
        return minTextViewHeight * 5
    }
    
    // MARK: - External Bindable Properties
    var text: String {
        get { textView.text }
        set {
            textView.text = newValue
            updatePlaceholderVisibility()
            adjustTextViewHeight()
        }
    }

    // MARK: 폰트
    var font: UIFont = .systemFont(ofSize: 14) {
        didSet {
            textView.font = font
            placeholderLabel.font = font
        }
    }

    // MARK: 텍스트컬러
    var textColor: UIColor = .label {
        didSet { textView.textColor = textColor }
    }

    // MARK: 플레이스홀더
    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            updatePlaceholderVisibility()
        }
    }

    // MARK: 플레이스홀더 컬러
    var placeholderColor: UIColor = .secondaryLabel {
        didSet { placeholderLabel.textColor = placeholderColor }
    }

    // MARK: 부모뷰 배경색
    var composerColor: UIColor = .systemBackground {
        didSet { backgroundColor = composerColor }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        layout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layout()
    }

    // MARK: - 레이아웃 설정
    private func layout() {
        
        // MARK: 상단 좌우 radius
        self.layer.cornerRadius = 25
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        
        [self.textView, self.placeholderLabel].forEach(addSubview(_:))

        // MARK: TextVeiw 설정
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.font = font
        textView.textColor = textColor
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.textContainer.lineFragmentPadding = 0

        // MARK: PlaceHolder 설정
        placeholderLabel.font = font
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.numberOfLines = 1
        placeholderLabel.text = placeholder

        textView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-32)
            self.textViewHeightConstraint = make.height.equalTo(minTextViewHeight).constraint
        }

        placeholderLabel.snp.makeConstraints { make in
            make.leading.equalTo(textView).offset(8)
            make.top.equalTo(textView).offset(8)
        }
    }

    // MARK: - Dynamic Resize
    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !(textView.text?.isEmpty ?? true)
    }

    private func adjustTextViewHeight() {
        let fittingSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        let size = textView.sizeThatFits(fittingSize)

        let targetHeight = min(max(size.height, minTextViewHeight), maxTextViewHeight)
        textView.isScrollEnabled = size.height > maxTextViewHeight
        textViewHeightConstraint?.update(offset: targetHeight)
        layoutIfNeeded()
    }

    // MARK: - UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        adjustTextViewHeight()
    }
}
