//
//  APIKeyInputViewController.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class APIKeyInputViewController: UIViewController {
    private let saveUseCase: SaveAPIKeyUseCase
    private let completion: () -> Void

    // MARK: disposeBag
    private let disposeBag = DisposeBag()
    
    // MARK: 저장버튼 영역뷰의 하단 제약 저장 (키보드 대응)
    private var searchViewBottomConstraint: Constraint?
    
    // MARK: title Label
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeColor.label1
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.text = "👋반갑습니다!"
        
        return label
    }()
    
    // MARK: linked Label
    let linkedLabel: LinkLabel = {
        let label = LinkLabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = ThemeColor.label2
        label.setTextWithLink(fullText: "OpenAI 개발자 페이지에서 로그인 후, API Key를 생성하여 여기에 입력해주세요.",
                              linkText: "OpenAI 개발자 페이지",
                              linkURL: URL(string: "https://platform.openai.com/account/api-keys")!)
        
        return label
    }()
    
    // MARK: API Key를 입력할 텍스트필드
    private lazy var apiKeyTextField: BorderedTextField = {
       let textfield = BorderedTextField()
        textfield.placeholder = "예: sk-XXXXXXXXXXXXXXXXXXXXXXXXX"
        return textfield
    }()
    
    // MARK: 저장 버튼
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = ThemeColor.positive
        button.setTitle("저장", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.setTitleColor(ThemeColor.label3, for: .normal)
        
        return button
    }()
    

    init(saveUseCase: SaveAPIKeyUseCase, completion: @escaping () -> Void) {
        self.saveUseCase = saveUseCase
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // MARK: KeyboardAdjustable 프로토콜의 키보드 옵져버 제거
        self.removeKeyboardObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.layout()
        self.bind()
    }
    
    private func layout() {
        self.view.backgroundColor = ThemeColor.background1
        
        // MARK: apiKey를 입력할 컴포넌트들이 위치할 뷰
        let inputView = UIView()
        
        // MARK: 하단 저장 버튼이 위치할 뷰
        let buttonView = UIView()
        buttonView.backgroundColor = ThemeColor.positive
        buttonView.addSubview(self.saveButton)
        
        [inputView, buttonView].forEach(self.view.addSubview(_:))
        [self.titleLabel, self.apiKeyTextField, self.linkedLabel].forEach(inputView.addSubview(_:))
        
        inputView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualTo(buttonView.snp.top).offset(-20)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        self.apiKeyTextField.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(56)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        self.linkedLabel.snp.makeConstraints { make in
            make.top.equalTo(self.apiKeyTextField.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
        
        buttonView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            self.searchViewBottomConstraint = make.bottom.equalToSuperview().constraint
        }
        
        self.saveButton.snp.makeConstraints { make in
            make.bottom.equalTo(buttonView.safeAreaLayoutGuide)
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(56)
        }
    }
    
    private func bind() {
        
        // MARK: KeyboardAdjustable 프로토콜의 옵저버 추가
        self.addKeyboardObservers()
        
        // MARK: 저장버튼 탭 바인딩
        self.saveButton.rx.tap
            .withLatestFrom(self.apiKeyTextField.rx.text.orEmpty)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] key in
                guard let self = self else { return }
                try? self.saveUseCase.execute(key: key)
                self.completion()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Place for extension with KeyboardAdjustable
extension APIKeyInputViewController: KeyboardAdjustable {
    var adjustableBottomConstraint: Constraint? {
        get { return self.searchViewBottomConstraint }
        set { self.searchViewBottomConstraint = newValue }
    }
}
