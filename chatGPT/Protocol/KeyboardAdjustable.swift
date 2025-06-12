//
//  KeyboardAdjustable.swift
//  chatGPT
//
//  Created by 홍정연 on 6/12/25.
//

import UIKit
import SnapKit

// MARK: 키보드를 기준으로 제약조건을 조정하는 공용 프로토콜
protocol KeyboardAdjustable: AnyObject {
    /// 키보드에 따라 조정할 하단 제약
    var adjustableBottomConstraint: Constraint? { get set }
    
    /// 키보드 높이에 따른 오프셋을 업데이트합니다.
    func updateKeyboardOffset(_ offset: CGFloat)
    
    /// 키보드 옵저버를 추가합니다.
    func addKeyboardObservers()
    
    /// 키보드 옵저버를 제거합니다.
    func removeKeyboardObservers()
}


extension KeyboardAdjustable where Self: UIViewController {
    func addKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self = self,
                  let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else { return }
            // searchView가 키보드 위에 딱 붙도록 오프셋을 -키보드 높이로 설정
            self.updateKeyboardOffset(-keyboardFrame.height)
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            self?.updateKeyboardOffset(0)
        }
    }
    
    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func updateKeyboardOffset(_ offset: CGFloat) {
        adjustableBottomConstraint?.update(offset: offset)
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}

