//
//  BorderedTextView.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class BorderedTextView: UIView {
    
    private let textView = UITextView()
    private let placeholderLabel = UILabel()

    // MARK: - 외부 바인딩용 프로퍼티
    var text: String? {
        get { textView.text }
        set {
            textView.text = newValue
            updatePlaceholderVisibility()
            invalidateIntrinsicContentSize()
        }
    }
    
    var font: UIFont = .systemFont(ofSize: 14) {
        didSet {
            textView.font = font
            placeholderLabel.font = font
            invalidateIntrinsicContentSize()
        }
    }
    
    var textColor: UIColor = .label {
        didSet { textView.textColor = textColor }
    }

    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            updatePlaceholderVisibility()
        }
    }
    
    var placeholderColor: UIColor = .secondaryLabel {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }

    var isEditable: Bool = true {
        didSet {
            textView.isEditable = isEditable
        }
    }
    
    var delegate: UITextViewDelegate? {
        didSet {
            textView.delegate = self
            externalDelegate = delegate
        }
    }
    
    var onTextChanged: ((String?) -> Void)?
    
    // MARK: - 상태별 스타일
    var isEnabled: Bool = true {
        didSet {
            textView.isUserInteractionEnabled = isEnabled
            updateAppearance()
        }
    }
    
    var normalBackgroundColor: UIColor = .white
    var selectedBackgroundColor: UIColor = .white
    var disabledBackgroundColor: UIColor = .systemGray6

    var normalBorderColor: UIColor = .systemGray4
    var selectedBorderColor: UIColor = .systemBlue
    var disabledBorderColor: UIColor = .systemGray3

    var borderWidth: CGFloat = 1.0 {
        didSet { layer.borderWidth = borderWidth }
    }

    var cornerRadius: CGFloat = 8.0 {
        didSet { layer.cornerRadius = cornerRadius }
    }

    // MARK: - 내부 상태
    private var isBeingEdited = false
    private weak var externalDelegate: UITextViewDelegate?

    // MARK: - 초기화
    override init(frame: CGRect) {
        super.init(frame: frame)
        layout()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layout()
    }

    private func layout() {
        layer.borderWidth = borderWidth
        layer.cornerRadius = cornerRadius
        layer.borderColor = normalBorderColor.cgColor
        backgroundColor = normalBackgroundColor
        clipsToBounds = true

        // TextView
        textView.backgroundColor = .clear
        textView.textColor = textColor
        textView.font = font
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0

        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        // Placeholder Label
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.font = font
        placeholderLabel.numberOfLines = 0
        addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.top)
            make.leading.trailing.equalTo(textView)
        }

        updatePlaceholderVisibility()
        updateAppearance()
    }

    private func updateAppearance() {
        if !isEnabled {
            backgroundColor = disabledBackgroundColor
            layer.borderColor = disabledBorderColor.cgColor
            textView.textColor = .secondaryLabel
        } else if isBeingEdited {
            backgroundColor = selectedBackgroundColor
            layer.borderColor = selectedBorderColor.cgColor
            textView.textColor = textColor
        } else {
            backgroundColor = normalBackgroundColor
            layer.borderColor = normalBorderColor.cgColor
            textView.textColor = textColor
        }
    }

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !(textView.text?.isEmpty ?? true)
    }

    override var intrinsicContentSize: CGSize {
        let width = bounds.width - textView.textContainerInset.left - textView.textContainerInset.right
        let textSize = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: textSize.height + 24)
    }

    func updateContentSize() {
        invalidateIntrinsicContentSize()
    }
}

// MARK: - UITextViewDelegate 중계
extension BorderedTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateContentSize()
        onTextChanged?(textView.text)
        externalDelegate?.textViewDidChange?(textView)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        isBeingEdited = true
        updateAppearance()
        externalDelegate?.textViewDidBeginEditing?(textView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        isBeingEdited = false
        updateAppearance()
        externalDelegate?.textViewDidEndEditing?(textView)
    }
}

