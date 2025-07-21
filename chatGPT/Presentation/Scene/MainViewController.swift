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
import PhotosUI
import UniformTypeIdentifiers

final class MainViewController: UIViewController {
    
    // MARK: 모델조회 UseCase
    private let fetchModelsUseCase: FetchModelConfigsUseCase
    
    // MARK: 채팅관련 ViewModel
    private let chatViewModel: ChatViewModel
    private let signOutUseCase: SignOutUseCase
    private let observeConversationsUseCase: ObserveConversationsUseCase
    private let updateTitleUseCase: UpdateConversationTitleUseCase
    private let deleteConversationUseCase: DeleteConversationUseCase
    private let loadUserImageUseCase: LoadUserProfileImageUseCase
    private let observeAuthStateUseCase: ObserveAuthStateUseCase
    private let parseMarkdownUseCase: ParseMarkdownUseCase
    private let fetchPreferenceUseCase: FetchUserPreferenceUseCase
    private let updatePreferenceUseCase: UpdateUserPreferenceUseCase
    private let fetchConversationMessagesUseCase: FetchConversationMessagesUseCase

    private let disposeBag = DisposeBag()

    private var availableModels: [ModelConfig] = []
    
    
    // MARK: 선택된 chatGPT 모델
    private var selectedModel: OpenAIModel = ModelPreference.current {
        didSet {
            ModelPreference.save(selectedModel)
            updatePlusButtonState()
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
        let button = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: nil, action: nil)
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
            updateTitleUseCase: updateTitleUseCase,
            deleteConversationUseCase: deleteConversationUseCase,
            fetchMessagesUseCase: fetchConversationMessagesUseCase,
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
        menuVC.onConversationDeleted = { [weak self] id in
            guard let self else { return }
            if self.chatViewModel.conversationID == id {
                self.chatViewModel.startNewConversation()
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

    
    init(fetchModelsUseCase: FetchModelConfigsUseCase,
         sendChatMessageUseCase: SendChatWithContextUseCase,
         summarizeUseCase: SummarizeMessagesUseCase,
         saveConversationUseCase: SaveConversationUseCase,
       appendMessageUseCase: AppendMessageUseCase,
       fetchConversationMessagesUseCase: FetchConversationMessagesUseCase,
       contextRepository: ChatContextRepository,
      observeConversationsUseCase: ObserveConversationsUseCase,
      signOutUseCase: SignOutUseCase,
      updateTitleUseCase: UpdateConversationTitleUseCase,
      deleteConversationUseCase: DeleteConversationUseCase,
      loadUserImageUseCase: LoadUserProfileImageUseCase,
      observeAuthStateUseCase: ObserveAuthStateUseCase,
      parseMarkdownUseCase: ParseMarkdownUseCase,
      fetchPreferenceUseCase: FetchUserPreferenceUseCase,
       updatePreferenceUseCase: UpdateUserPreferenceUseCase,
       uploadFilesUseCase: UploadFilesUseCase) {
        self.fetchModelsUseCase = fetchModelsUseCase
       self.chatViewModel = ChatViewModel(sendMessageUseCase: sendChatMessageUseCase,
                                           summarizeUseCase: summarizeUseCase,
                                           saveConversationUseCase: saveConversationUseCase,
                                           appendMessageUseCase: appendMessageUseCase,
                                           fetchMessagesUseCase: fetchConversationMessagesUseCase,
                                           contextRepository: contextRepository,
                                           fetchPreferenceUseCase: fetchPreferenceUseCase,
                                           updatePreferenceUseCase: updatePreferenceUseCase,
                                           uploadFilesUseCase: uploadFilesUseCase)
        self.fetchConversationMessagesUseCase = fetchConversationMessagesUseCase
        self.signOutUseCase = signOutUseCase
        self.observeConversationsUseCase = observeConversationsUseCase
        self.updateTitleUseCase = updateTitleUseCase
        self.deleteConversationUseCase = deleteConversationUseCase
        self.loadUserImageUseCase = loadUserImageUseCase
        self.observeAuthStateUseCase = observeAuthStateUseCase
        self.parseMarkdownUseCase = parseMarkdownUseCase
        self.fetchPreferenceUseCase = fetchPreferenceUseCase
        self.updatePreferenceUseCase = updatePreferenceUseCase
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
        self.configurePlusButtonMenu()
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
        self.composerView.onSendButtonTapped = { [weak self] text, items in
            guard let self else { return }
            self.chatViewModel.send(prompt: text,
                                    attachments: items,
                                    model: self.selectedModel,
                                    stream: self.streamEnabled)
        }
        self.composerView.onPlusButtonTapped = { [weak self] in
            self?.handleAlbumOption()
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
                    let heightChanged = cell.update(text: message.text, parser: self.parseMarkdownUseCase)
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
        fetchModelsUseCase.execute()
            .subscribe(onSuccess: { [weak self] models in
                guard let self else { return }
                self.availableModels = models
                self.updatePlusButtonState()
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: TableView Helpers
    private func createDataSource() -> UITableViewDiffableDataSource<Int, ChatViewModel.ChatMessage> {
        let dataSource = UITableViewDiffableDataSource<Int, ChatViewModel.ChatMessage>(tableView: tableView) { tableView, indexPath, message in
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCell
            cell.configure(with: message, parser: self.parseMarkdownUseCase)
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
            dataSource.applySnapshotUsingReloadData(snapshot)
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

    private func updatePlusButtonState() {
        let config = availableModels.first { $0.modelId == selectedModel.id }
        composerView.plusButtonEnabled = config?.vision ?? false
    }

    private func configurePlusButtonMenu() {
        let photoAction = UIAction(title: "사진", image: UIImage(systemName: "camera")) { [weak self] _ in
            self?.presentCamera()
        }
        let albumAction = UIAction(title: "앨범", image: UIImage(systemName: "photo")) { [weak self] _ in
            self?.handleAlbumOption()
        }
        let fileAction = UIAction(title: "파일", image: UIImage(systemName: "doc")) { [weak self] _ in
            self?.presentDocumentPicker()
        }
        composerView.plusButtonMenu = UIMenu(title: "", children: [photoAction, albumAction, fileAction])
        composerView.onPlusButtonTapped = nil
    }

    private func handleAlbumOption() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            presentPhotoPicker()
        case .denied, .restricted:
            presentPermissionAlert()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.presentPhotoPicker()
                    }
                }
            }
        @unknown default:
            break
        }
    }

    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data], asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentPermissionAlert() {
        let alert = UIAlertController(title: "사진 접근 권한 필요", message: "설정에서 권한을 허용해주세요", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "설정", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
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

extension MainViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        let group = DispatchGroup()
        var images: [UIImage?] = Array(repeating: nil, count: results.count)

        for (index, result) in results.enumerated() {
            let provider = result.itemProvider
            if provider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        images[index] = image
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            let newImages = images.compactMap { $0 }
            guard !newImages.isEmpty else { return }
            var current = self.composerView.attachments.value
            current.append(contentsOf: newImages.map { .image($0) })
            self.composerView.attachments.accept(current)
        }
    }
}

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            var current = composerView.attachments.value
            current.append(.image(image))
            composerView.attachments.accept(current)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)
        guard !urls.isEmpty else { return }
        var current = composerView.attachments.value
        current.append(contentsOf: urls.map { .file($0) })
        composerView.attachments.accept(current)
    }
}

