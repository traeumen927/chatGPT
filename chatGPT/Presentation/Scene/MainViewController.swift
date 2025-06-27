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
    private let signOutUseCase: SignOutUseCase
    private let observeConversationsUseCase: ObserveConversationsUseCase
    private let loadUserImageUseCase: LoadUserProfileImageUseCase
    private let observeAuthStateUseCase: ObserveAuthStateUseCase

    private let disposeBag = DisposeBag()

    private var availableModels: [OpenAIModel] = []
    
    
    // MARK: 선택된 chatGPT 모델
    private var selectedModel: OpenAIModel = ModelPreference.current {
        didSet {
            ModelPreference.save(selectedModel)
        }
    }
    
    private var streamEnabled: Bool = ModelPreference.streamEnabled {
        didSet {
            guard oldValue != streamEnabled else { return }
            ModelPreference.saveStreamEnabled(streamEnabled)
        }
    }
    
    // MARK: 새 대화 버튼
    private lazy var newChatButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        return button
    }()
    
    // MARK: 메뉴 버튼
    private lazy var menuBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: nil, style: .plain, target: self, action: nil)
        button.tintColor = .clear
        return button
    }()
    
    
    // MARK: 메뉴 화면 프레젠트용
    private func presentMenu() {
        let menuVC = MenuViewController(
            observeConversationsUseCase: observeConversationsUseCase,
            signOutUseCase: signOutUseCase,
            fetchModelsUseCase: fetchModelsUseCase,
            selectedModel: selectedModel,
            streamEnabled: streamEnabled,
            currentConversationID: chatViewModel.conversationID,
            draftExists: chatViewModel.hasDraft,
            availableModels: availableModels
        )
        menuVC.modalPresentationStyle = .formSheet
        menuVC.onModelSelected = { [weak self] model in
            self?.selectedModel = model
        }
        menuVC.onStreamChanged = { [weak self] isOn in
            self?.streamEnabled = isOn
        }
        menuVC.onConversationSelected = { [weak self] id in
            guard let self else { return }
            if let id {
                self.chatViewModel.loadConversation(id: id)
            } else {
                if self.chatViewModel.hasDraft {
                    self.chatViewModel.resumeDraftConversation()
                } else {
                    self.chatViewModel.startNewConversation()
                }
            }
        }
        menuVC.onClose = { [weak menuVC] in
            menuVC?.dismiss(animated: true)
        }
        present(menuVC, animated: true)
    }
    
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
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        return tableView
    }()
    
    // MARK: 저장버튼 영역뷰의 하단 제약 저장 (키보드 대응)
    private var composerViewBottomConstraint: Constraint?
    
    // MARK: 채팅 dataSource
    private var dataSource: UITableViewDiffableDataSource<Int, ChatViewModel.ChatMessage>!

    
    init(fetchModelsUseCase: FetchAvailableModelsUseCase,
         sendChatMessageUseCase: SendChatWithContextUseCase,
         summarizeUseCase: SummarizeMessagesUseCase,
         saveConversationUseCase: SaveConversationUseCase,
         appendMessageUseCase: AppendMessageUseCase,
         fetchConversationMessagesUseCase: FetchConversationMessagesUseCase,
         contextRepository: ChatContextRepository,
         observeConversationsUseCase: ObserveConversationsUseCase,
         signOutUseCase: SignOutUseCase,
         loadUserImageUseCase: LoadUserProfileImageUseCase,
         observeAuthStateUseCase: ObserveAuthStateUseCase) {
        self.fetchModelsUseCase = fetchModelsUseCase
        self.chatViewModel = ChatViewModel(sendMessageUseCase: sendChatMessageUseCase,
                                           summarizeUseCase: summarizeUseCase,
                                           saveConversationUseCase: saveConversationUseCase,
                                           appendMessageUseCase: appendMessageUseCase,
                                           fetchMessagesUseCase: fetchConversationMessagesUseCase,
                                           contextRepository: contextRepository)
        self.signOutUseCase = signOutUseCase
        self.observeConversationsUseCase = observeConversationsUseCase
        self.loadUserImageUseCase = loadUserImageUseCase
        self.observeAuthStateUseCase = observeAuthStateUseCase
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
        self.preloadModels()
    }
    
    private func layout() {
        self.navigationItem.title = "ChatGPT"
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.leftBarButtonItem = menuBarButton
        
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
        
        observeAuthStateUseCase.execute()
            .subscribe(onNext: { [weak self] _ in
                self?.loadUserImage()
            })
            .disposed(by: disposeBag)
        
        
        // MARK: ChatComposerView 전송버튼 클로져
        self.composerView.onSendButtonTapped = { [weak self] text in
            guard let self = self else { return }
            self.chatViewModel.send(prompt: text,
                                    model: self.selectedModel,
                                    stream: self.streamEnabled)
        }
        
        // 메시지 상태 → UI 업데이트
        self.dataSource = createDataSource()
        self.chatViewModel.messages
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] messages in
                self?.applySnapshot(messages)
            })
            .disposed(by: disposeBag)
        
        chatViewModel.streamingMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                guard let self else { return }
                
                // 메시지가 변경된 인덱스 탐색
                guard let index = self.chatViewModel.messages.value.firstIndex(where: { $0.id == message.id }) else { return }
                let indexPath = IndexPath(row: index, section: 0)
                
                // 셀을 찾아 직접 업데이트
                if let cell = self.tableView.cellForRow(at: indexPath) as? ChatMessageCell {
                    let heightChanged = cell.update(text: message.text)
                    if heightChanged {
                        UIView.performWithoutAnimation {
                            self.tableView.beginUpdates()
                            self.tableView.endUpdates()
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
        

        
        menuBarButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.presentMenu()
            })
            .disposed(by: disposeBag)
        
        chatViewModel.conversationIDObservable
            .distinctUntilChanged { $0 == $1 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] id in
                self?.navigationItem.rightBarButtonItem = id == nil ? nil : self?.newChatButton
            })
            .disposed(by: disposeBag)
        
        newChatButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.chatViewModel.startNewConversation()
            })
            .disposed(by: disposeBag)
        
    }
    
    private func preloadModels() {
        fetchModelsUseCase.execute { [weak self] result in
            guard case let .success(models) = result else { return }
            self?.availableModels = models
        }
    }
    
    
    // MARK: TableView Helpers
    private func createDataSource() -> UITableViewDiffableDataSource<Int, ChatViewModel.ChatMessage> {
        let dataSource = UITableViewDiffableDataSource<Int, ChatViewModel.ChatMessage>(tableView: tableView) { tableView, indexPath, message in
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCell
            cell.configure(with: message)
            return cell
        }
        dataSource.defaultRowAnimation = .none
        return dataSource
    }

    private func applySnapshot(_ messages: [ChatViewModel.ChatMessage]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatViewModel.ChatMessage>()
        snapshot.appendSections([0])
        snapshot.appendItems(messages)
        UIView.performWithoutAnimation {
            dataSource.apply(snapshot, animatingDifferences: false)
            if !messages.isEmpty {
                tableView.layoutIfNeeded()
            }
        }
        scrollToBottom()
    }

    private func scrollToBottom() {
        guard !chatViewModel.messages.value.isEmpty else { return }
        let lastRow = chatViewModel.messages.value.count - 1
        let indexPath = IndexPath(row: lastRow, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }

    
    private func loadUserImage() {
        loadUserImageUseCase.execute()
            .map { image -> UIImage in
                let resized = image.resize(to: CGSize(width: 32, height: 32))
                let rounded = resized.withRoundedCorners(radius: 16)
                return rounded.withRenderingMode(.alwaysOriginal)
            }
            .do(onSuccess: { [weak self] _ in
                self?.menuBarButton.tintColor = nil
            }, onError: { [weak self] _ in
                self?.menuBarButton.tintColor = ThemeColor.label1
            })
            .catchAndReturn(defaultProfileImage())
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] image in
                self?.menuBarButton.image = image
            })
            .disposed(by: disposeBag)
    }
    private func defaultProfileImage() -> UIImage {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        return UIImage(systemName: "person.circle.fill", withConfiguration: config) ?? UIImage()
    }
}


// MARK: - Place for extension with KeyboardAdjustable
extension MainViewController: KeyboardAdjustable {
    var adjustableBottomConstraint: Constraint? {
        get { return self.composerViewBottomConstraint }
        set { self.composerViewBottomConstraint = newValue }
    }
}

