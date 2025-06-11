//
//  APIKeyInputViewController.swift
//  chatGPT
//
//  Created by 홍정연 on 6/11/25.
//

import UIKit

final class APIKeyInputViewController: UIViewController {
    private let saveUseCase: SaveAPIKeyUseCase
    private let completion: () -> Void

    private let textField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.placeholder = "Enter API Key"
        return field
    }()

    init(saveUseCase: SaveAPIKeyUseCase, completion: @escaping () -> Void) {
        self.saveUseCase = saveUseCase
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
    }

    private func setupLayout() {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.addTarget(self, action: #selector(saveKey), for: .touchUpInside)

        textField.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(textField)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textField.widthAnchor.constraint(equalToConstant: 250),

            button.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc
    private func saveKey() {
        guard let key = textField.text, !key.isEmpty else { return }
        try? saveUseCase.execute(key: key)
        completion()
    }
}
