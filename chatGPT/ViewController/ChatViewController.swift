//
//  ChatViewController.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/05.
//

import UIKit
import RxSwift
import RxGesture
import SnapKit

class ChatViewController: UIViewController {
    
    let viewModel: ChatViewModel!
    let dispostBag = DisposeBag()
    
    private var messageList: [Message] = [Message]()
    
    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.register(chatCell.self, forCellReuseIdentifier: chatCell.cellId)
        view.separatorStyle = .none
        
        return view
    }()
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layout()
        bind()
    }
    
    private func layout() {
        self.view.backgroundColor = .systemBackground
        
        let inputView = InputView()
        [tableView, inputView].forEach(self.view.addSubview(_:))
        inputView.delegate = self
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputView.snp.top)
        }
        
        inputView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide)
        }
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func bind() {
        self.viewModel.messageSubject.subscribe(onNext: { [weak self] message in
            guard let self = self else {return}
            self.messageList.append(message)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }).disposed(by: dispostBag)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}

extension ChatViewController: InputViewProtocol {
    func beginEditing() {
        
    }
    
    func endEditing() {
        
    }
    
    func enterPressed(question: String) {
        self.viewModel.askQuestion(question: question)
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: chatCell.cellId, for: indexPath) as! chatCell
        cell.bind(data: self.messageList[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
}
