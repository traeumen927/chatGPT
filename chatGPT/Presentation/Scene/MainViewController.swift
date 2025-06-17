//
//  MainViewController.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MainViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    // MARK: 선택된 chatGPT 모델
    private var selectedModel: OpenAIModel = ModelPreference.current {
        didSet {
            ModelPreference.current = selectedModel
            self.updateModelButton()
        }
    }
    
    // MARK: 모델 선택 버튼
    private lazy var modelButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "", primaryAction: nil, menu: nil)
        return button
    }()
    
    // MARK: 채팅관련 컴포져뷰
    private lazy var composerView: ChatComposerView = {
        let view = ChatComposerView()
        view.placeholder = "무엇이든 물어보세요."
        view.composerColor = ThemeColor.background3
        
        return view
    }()
    
    // MARK: 저장버튼 영역뷰의 하단 제약 저장 (키보드 대응)
    private var composerViewBottomConstraint: Constraint?
    
    
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
        self.navigationItem.title = "ChatGPT"
        self.navigationItem.rightBarButtonItem = modelButton
        
        // MARK: 모델 버튼 초기 설정
        self.updateModelButton()
        
        self.view.backgroundColor = ThemeColor.background1
        
        [self.composerView].forEach(self.view.addSubview(_:))
        
        self.composerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            self.composerViewBottomConstraint = make.bottom.equalToSuperview().constraint
        }
    }
    
    private func bind(){
        // MARK: KeyboardAdjustable 프로토콜의 옵저버 추가
        self.addKeyboardObservers()
        
        // MARK: ChatComposerView 전송버튼 클로져
        self.composerView.onSendButtonTapped = { [weak self] text in
            guard let self = self else { return }
            
            print("질문: \(text)")
            
            let repository = KeychainAPIKeyRepository()
            let openAIService = OpenAIService(apiKeyRepository: repository)
            
            openAIService.request(
                .chat(prompt: text, model: .gpt35, stream: false)) { result in
                    switch result {
                    case .success(let text):
                        print("답변: \(text)")
                    case .failure(let error):
                        if let openAIError = error as? OpenAIError {
                            print("❌ OpenAI 오류: \(openAIError.errorMessage)")
                        } else {
                            print("❌ 일반 오류: \(error.localizedDescription)")
                        }
                    }
                }
        }
    }
    
    // MARK: 드랍 메뉴 생성
    private func createModelMenu() -> UIMenu {
        UIMenu(
            title: "모델 선택",
            options: .displayInline,
            children: OpenAIModel.allCases.map { model in
                UIAction(title: model.displayName,
                         state: model == selectedModel ? .on : .off) { [weak self] _ in
                    self?.selectedModel = model
                }
            }
        )
    }
    
    // MARK: 모델 버튼 변경
    private func updateModelButton() {
        modelButton.title = selectedModel.displayName
        modelButton.menu = UIMenu(
            title: "모델 선택",
            options: .displayInline,
            children: OpenAIModel.allCases.map { model in
                UIAction(title: model.displayName,
                         state: model == selectedModel ? .on : .off) { [weak self] _ in
                    self?.selectedModel = model
                }
            }
        )
    }
}

// MARK: - Place for extension with KeyboardAdjustable
extension MainViewController: KeyboardAdjustable {
    var adjustableBottomConstraint: Constraint? {
        get { return self.composerViewBottomConstraint }
        set { self.composerViewBottomConstraint = newValue }
    }
}
