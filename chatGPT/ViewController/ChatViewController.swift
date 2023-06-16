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
    
    // MARK: Feedback Haptic
    var feedBackGenerator: UINotificationFeedbackGenerator?
    
    private var bubbleList: [Bubble] = [Bubble]()
    
    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.register(chatCell.self, forCellReuseIdentifier: chatCell.cellId)
        view.separatorStyle = .none
        
        return view
    }()
    
    private let settingButton: UIBarButtonItem = {
        let view = UIBarButtonItem()
        view.image = UIImage(systemName: "gearshape.fill")
        view.tintColor = .label
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
        self.title = "chatGPT"
        self.view.backgroundColor = .systemBackground
        
        self.navigationItem.rightBarButtonItem = settingButton
        
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
        
        
        // MARK: setup Feedback Haptic
        self.feedBackGenerator = UINotificationFeedbackGenerator()
        self.feedBackGenerator?.prepare()
        
        // MARK: Keyboard add Observer by Hide/Show
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func bind() {
        
        // MARK: 채팅(말풍선) 구독
        self.viewModel.bubbleRelay.subscribe(onNext: { [weak self] bubble in
            guard let self = self else {return}
            self.bubbleList = bubble
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }).disposed(by: dispostBag)
        
        // MARK: 채팅(말풍선) 완료 구독
        self.viewModel.completeSubject.subscribe(onNext: { [weak self] _ in
            guard let self = self else {return}
            self.tableView.scrollToBottom(isAnimated: true)
            
            // MARK: Success Haptic Feedback
            if Setting.shared.haptic {
                self.feedBackGenerator?.notificationOccurred(.success)
            }
        }).disposed(by: dispostBag)
        
        
        // MARK: 로딩 여부 구독
        self.viewModel.loadingSubject.subscribe(onNext: { [weak self] isLoading in
            guard let self = self else {return}
            isLoading ? self.showLoading() : self.hideLoading()
        }).disposed(by: dispostBag)
        
        
        
        // MARK: Setting 버튼이 눌림
        self.settingButton.rx.tap.bind(onNext: { [weak self] in
            guard let self = self else {return}
            let nc = UINavigationController(rootViewController: SettingViewController(viewModel: SettingViewModel()))
            self.present(nc, animated: true)
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
    
    func enterPressed(chat: String) {
        self.viewModel.chatEntered(chat: chat)
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bubbleList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: chatCell.cellId, for: indexPath) as! chatCell
        cell.bind(data: self.bubbleList[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
}
