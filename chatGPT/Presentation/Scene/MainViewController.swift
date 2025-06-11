//
//  MainViewController.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import UIKit

final class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "openAI.apiKey"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
