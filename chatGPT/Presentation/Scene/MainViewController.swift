//
//  MainViewController.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import UIKit
import SnapKit

final class MainViewController: UIViewController {
    
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
        view.backgroundColor = ThemeColor.background1
        
        [self.composerView].forEach(self.view.addSubview(_:))
        
        self.composerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            self.composerViewBottomConstraint = make.bottom.equalToSuperview().constraint
        }
    }
    
    private func bind(){
        // MARK: KeyboardAdjustable 프로토콜의 옵저버 추가
        self.addKeyboardObservers()
    }
}

// MARK: - Place for extension with KeyboardAdjustable
extension MainViewController: KeyboardAdjustable {
    var adjustableBottomConstraint: Constraint? {
        get { return self.composerViewBottomConstraint }
        set { self.composerViewBottomConstraint = newValue }
    }
}
