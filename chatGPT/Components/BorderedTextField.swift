//
//  BorderedTextField.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class BorderedTextField: UIView {
    
    // MARK: - 내부 텍스트 필드
    fileprivate let textField = UITextField()
    
    // MARK: - 외부 바인딩용 프로퍼티
    
    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    var placeholder: String? {
        didSet { updatePlaceholder() }
    }
    
    var placeholderColor: UIColor = .lightGray {
        didSet { updatePlaceholder() }
    }
    
    var font: UIFont = .systemFont(ofSize: 14) {
        didSet { textField.font = font }
    }
    
    var textAlignment: NSTextAlignment = .left {
        didSet { textField.textAlignment = textAlignment }
    }
    
    var keyboardType: UIKeyboardType = .default {
        didSet { textField.keyboardType = keyboardType }
    }
    
    var returnKeyType: UIReturnKeyType = .default {
        didSet { textField.returnKeyType = returnKeyType }
    }

    var isSecureTextEntry: Bool = false {
        didSet { textField.isSecureTextEntry = isSecureTextEntry }
    }

    var autocapitalizationType: UITextAutocapitalizationType = .none {
        didSet { textField.autocapitalizationType = autocapitalizationType }
    }

    var autocorrectionType: UITextAutocorrectionType = .no {
        didSet { textField.autocorrectionType = autocorrectionType }
    }

    var delegate: UITextFieldDelegate? {
        get { textField.delegate }
        set { textField.delegate = newValue }
    }
    
    var onTextChanged: ((String?) -> Void)?
    
    // MARK: - 상태 제어
    var isEnabled: Bool = true {
        didSet {
            textField.isUserInteractionEnabled = isEnabled
            updateAppearance()
        }
    }
    
    private var isBeingEdited: Bool = false

    // MARK: - 색상 설정
    
    var borderWidth: CGFloat = 1.0 {
        didSet { layer.borderWidth = borderWidth }
    }
    
    var cornerRadius: CGFloat = 8.0 {
        didSet { layer.cornerRadius = cornerRadius }
    }

    var normalFontColor: UIColor = .label
    var disabledFontColor: UIColor = .secondaryLabel

    var normalBorderColor: UIColor = .systemGray4
    var selectedBorderColor: UIColor = .systemBlue
    var disabledBorderColor: UIColor = .systemGray3

    var normalBackgroundColor: UIColor = .white
    var selectedBackgroundColor: UIColor = .white
    var disabledBackgroundColor: UIColor = .systemGray6
    
    // MARK: - 초기화
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = normalBorderColor.cgColor
        backgroundColor = normalBackgroundColor
        clipsToBounds = true

        addSubview(textField)
        textField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        textField.font = font
        textField.textColor = normalFontColor
        textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        // 좌측 여백 강제 삽입
        let spacer = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        textField.leftView = spacer
        textField.leftViewMode = .always
    }

    private func updateAppearance() {
        if !isEnabled {
            backgroundColor = disabledBackgroundColor
            layer.borderColor = disabledBorderColor.cgColor
            textField.textColor = disabledFontColor
        } else if isBeingEdited {
            backgroundColor = selectedBackgroundColor
            layer.borderColor = selectedBorderColor.cgColor
            textField.textColor = normalFontColor
        } else {
            backgroundColor = normalBackgroundColor
            layer.borderColor = normalBorderColor.cgColor
            textField.textColor = normalFontColor
        }
    }

    private func updatePlaceholder() {
        guard let placeholder = placeholder else {
            textField.attributedPlaceholder = nil
            return
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: placeholderColor
        ]
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributes)
    }

    @objc private func editingDidBegin() {
        isBeingEdited = true
        updateAppearance()
    }

    @objc private func editingDidEnd() {
        isBeingEdited = false
        updateAppearance()
    }

    @objc private func textDidChange() {
        onTextChanged?(textField.text)
    }
}

// MARK: - Rx 확장
extension Reactive where Base: BorderedTextField {
    var text: ControlProperty<String?> {
        base.textField.rx.text
    }

    var editingDidEndOnExit: ControlEvent<Void> {
        base.textField.rx.controlEvent(.editingDidEndOnExit)
    }
}
