//
//  UIViewController.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/07.
//

import UIKit

extension UIViewController {
    func showLoading() {
        DispatchQueue.main.async {
            let loadingIndicatorView: UIActivityIndicatorView
            
            // MARK: 기존의 UIActivityIndicatorView가 있는지 확인
            if let existedView = self.view.subviews.first(where: { $0 is UIActivityIndicatorView } ) as? UIActivityIndicatorView {
                loadingIndicatorView = existedView
            } else {
                // MARK: 기존의 UIActivityIndicatorView가 없으면 삽입
                loadingIndicatorView = UIActivityIndicatorView(style: .large)
                
                loadingIndicatorView.frame = self.view.frame
                loadingIndicatorView.color = .darkGray
                loadingIndicatorView.backgroundColor = .black.withAlphaComponent(0.1)
                self.view.addSubview(loadingIndicatorView)
            }
            
            loadingIndicatorView.startAnimating()
        }
    }
    
    func hideLoading() {
        DispatchQueue.main.async {
            self.view.subviews.filter({ $0 is UIActivityIndicatorView }).forEach { $0.removeFromSuperview() }
        }
    }
}
