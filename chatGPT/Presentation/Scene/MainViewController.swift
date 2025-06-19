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
    
    // MARK: 모델조회 UseCase
    private let fetchModelsUseCase: FetchAvailableModelsUseCase
    
    // MARK: 채팅관련 ViewModel
    private let chatViewModel: ChatViewModel
    
    private let disposeBag = DisposeBag()
    
    // MARK: 사용 가능한 chatGPT 모델
    private var availableModels: [OpenAIModel] = []
    
    // MARK: 선택된 chatGPT 모델
    private var selectedModel: OpenAIModel = ModelPreference.current {
        didSet {
            ModelPreference.save(selectedModel)
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
    
    // MARK: 테이블뷰
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
        tableView.keyboardDismissMode = .interactive
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        return tableView
    }()
    
    // MARK: 저장버튼 영역뷰의 하단 제약 저장 (키보드 대응)
    private var composerViewBottomConstraint: Constraint?
    
    // MARK: 채팅 dataSource
    private var dataSource: UITableViewDiffableDataSource<Int, ChatViewModel.ChatMessage>!
    
    init(fetchModelsUseCase: FetchAvailableModelsUseCase,
         sendChatMessageUseCase: SendChatWithContextUseCase,
         chatUseCase: ChatUseCase) {
        self.fetchModelsUseCase = fetchModelsUseCase
        self.chatViewModel = ChatViewModel(sendMessageUseCase: sendChatMessageUseCase,
                                           chatUseCase: chatUseCase)
        super.init(nibName: nil, bundle: nil)

        rx.viewDidLoad
            .bind { [weak self] in
                self?.layout()
                self?.bind()
            }
            .disposed(by: disposeBag)
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
    }
    
    private func layout() {
        self.navigationItem.title = "ChatGPT"
        self.navigationItem.rightBarButtonItem = modelButton
        
        // MARK: 모델 버튼 초기 설정
        self.updateModelButton()
        
        self.view.backgroundColor = ThemeColor.background1
        
        [self.tableView, self.composerView].forEach(self.view.addSubview(_:))
        
        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(composerView.snp.top)
        }
        
        self.composerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            self.composerViewBottomConstraint = make.bottom.equalToSuperview().constraint
        }
    }
    
    private func bind(){
        // MARK: KeyboardAdjustable 프로토콜의 옵저버 추가
        self.addKeyboardObservers()
        
        // MARK: 사용가능한 모델 fetch
        self.fetchAvailableModels()
        
        // MARK: ChatComposerView 전송버튼 클로져
        self.composerView.onSendButtonTapped = { [weak self] text in
            guard let self = self else { return }
            self.chatViewModel.send(prompt: text, model: self.selectedModel)
        }
        
        // 메시지 상태 → UI 업데이트
        self.dataSource = createDataSource()
        self.chatViewModel.messages
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] messages in
                self?.applySnapshot(messages)
            })
            .disposed(by: disposeBag)
        
    }
    
    private func updateModelButton() {
        
        // MARK: 모델명이 너무 긴 경우를 대비하여 truncate
        modelButton.title = selectedModel.displayName.truncated(limit: 13)
        
        modelButton.menu = UIMenu(
            title: "모델 선택",
            options: .displayInline,
            children: availableModels.map { model in
                UIAction(title: model.displayName,
                         state: model == selectedModel ? .on : .off) { [weak self] _ in
                    self?.selectedModel = model
                }
            }
        )
    }
    
    // MARK: 사용 가능 모델 조회
    private func fetchAvailableModels() {
        fetchModelsUseCase.execute { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let models):
                self.availableModels = models
                
                if !models.contains(self.selectedModel) {
                    self.selectedModel = models.first ?? OpenAIModel(id: "unknown")
                }
                
                self.updateModelButton()
                
            case .failure(let error):
                print("❌ 모델 로딩 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: TableView Helpers
    private func createDataSource() -> UITableViewDiffableDataSource<Int, ChatViewModel.ChatMessage> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, message in
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCell
            cell.configure(with: message)
            return cell
        }
    }
    
    private func applySnapshot(_ messages: [ChatViewModel.ChatMessage]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatViewModel.ChatMessage>()
        snapshot.appendSections([0])
        
        // 💡 transform이 적용된 상태에서는 reversed된 순서로 추가해야 아래부터 쌓임
        snapshot.appendItems(messages.reversed())

        dataSource.apply(snapshot, animatingDifferences: true)

        if !messages.isEmpty {
            let indexPath = IndexPath(row: 0, section: 0) // ⬅️ 가장 아래쪽 셀로 스크롤
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }

}

// MARK: - Place for extension with KeyboardAdjustable
extension MainViewController: KeyboardAdjustable {
    var adjustableBottomConstraint: Constraint? {
        get { return self.composerViewBottomConstraint }
        set { self.composerViewBottomConstraint = newValue }
    }
}
