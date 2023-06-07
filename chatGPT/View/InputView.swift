//
//  InputView.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/05.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class InputView: UIView {
    
    var disposeBag = DisposeBag()
    var delegate: InputViewProtocol?
    
    private let questionView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        return view
    }()
    
    private let questionText: UITextField = {
        let view = UITextField()
        view.placeholder = "Message"
        view.backgroundColor = .clear
        return view
    }()
    
    private let enterButton: UIButton = {
        let view = UIButton()
        view.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        view.tintColor = .systemBackground
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 14
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        layout()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layout() {
        self.addSubview(questionView)
        questionView.addSubview(questionText)
        self.addSubview(enterButton)
        questionText.delegate = self
        
        
        
        questionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalTo(enterButton.snp.leading).offset(-8)
            make.bottom.equalToSuperview().offset(-4)
        }
        
        questionText.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        enterButton.snp.makeConstraints { make in
            make.width.height.equalTo(28)
            make.centerY.equalTo(questionView.snp.centerY)
            make.trailing.equalToSuperview().offset(-12)
        }
    }
    
    private func bind() {
        self.enterButton.rx.tap.subscribe { [weak self] _ in
            guard let self = self,
                  let question = self.questionText.text else {return}
            self.questionText.text = nil
            self.delegate?.enterPressed(question: question)
        }.disposed(by: disposeBag)
    }
}

extension InputView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.questionView.backgroundColor = .systemBackground
        self.delegate?.beginEditing()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.questionView.backgroundColor = .systemGray5
        self.delegate?.endEditing()
    }
}
