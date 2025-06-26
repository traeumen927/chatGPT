import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MenuViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case model
        case history
        case account

        var title: String {
            switch self {
            case .model: return "모델"
            case .history: return "대화 히스토리"
            case .account: return "계정"
            }
        }
    }

    private var conversations: [ConversationSummary] = []
    private var availableModels: [OpenAIModel] = []
    private var selectedModel: OpenAIModel
    private var streamEnabled: Bool

    private let observeConversationsUseCase: ObserveConversationsUseCase
    private let signOutUseCase: SignOutUseCase
    private let fetchModelsUseCase: FetchAvailableModelsUseCase
    private var currentConversationID: String?
    private let draftExists: Bool
    private let disposeBag = DisposeBag()



    // 메뉴 닫기용 클로저
    var onClose: (() -> Void)?
    var onConversationSelected: ((String?) -> Void)?

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.register(StreamToggleCell.self, forCellReuseIdentifier: "StreamToggleCell")
        return tv
    }()
  

    var onModelSelected: ((OpenAIModel) -> Void)?
    var onStreamChanged: ((Bool) -> Void)?

    init(observeConversationsUseCase: ObserveConversationsUseCase,
         signOutUseCase: SignOutUseCase,
         fetchModelsUseCase: FetchAvailableModelsUseCase,
         selectedModel: OpenAIModel,
         streamEnabled: Bool,
         currentConversationID: String?,
         draftExists: Bool,
         availableModels: [OpenAIModel] = [],
         onClose: (() -> Void)? = nil) {
        self.observeConversationsUseCase = observeConversationsUseCase
        self.signOutUseCase = signOutUseCase
        self.fetchModelsUseCase = fetchModelsUseCase
        self.selectedModel = selectedModel
        self.streamEnabled = streamEnabled
        self.currentConversationID = currentConversationID
        self.draftExists = draftExists
        self.availableModels = availableModels
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout()
        bind()
        load()
        loadModels()
    }

    private func layout() {
        view.backgroundColor = ThemeColor.background1
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

    }


    private func bind() {
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)

                switch Section(rawValue: indexPath.section) {
                case .model:
                    if indexPath.row == 0 {
                        self.presentModelSelector()
                    }
                case .account:
                    do {
                        try self.signOutUseCase.execute()
                        self.onClose?()
                    } catch {
                        print("❌ Sign out failed: \(error.localizedDescription)")
                    }
                case .history:
                    let convo = self.conversations[indexPath.row]
                    self.currentConversationID = convo.id == "draft" ? nil : convo.id
                    self.onConversationSelected?(self.currentConversationID)
                    self.onClose?()
                case .none:
                    break
                }
            })
            .disposed(by: disposeBag)

    }

    private func load() {
        observeConversationsUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] list in
                guard let self else { return }
                var items = list
                if self.currentConversationID == nil || self.draftExists {
                    let draft = ConversationSummary(id: "draft", title: "새로운 대화", timestamp: Date())
                    items.insert(draft, at: 0)
                }
                self.conversations = items
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    private func loadModels() {
        fetchModelsUseCase.execute { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let models):
                self.availableModels = models
                let index = IndexSet(integer: Section.model.rawValue)
                self.tableView.reloadSections(index, with: .automatic)
            case .failure(let error):
                print("❌ 모델 로딩 실패: \(error.localizedDescription)")
            }
        }
    }

    private func presentModelSelector() {
        guard !availableModels.isEmpty else {
            let alert = UIAlertController(title: nil, message: "모델을 불러오는 중입니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

        let alert = UIAlertController(title: "모델 선택", message: nil, preferredStyle: .actionSheet)
        for model in availableModels {
            let action = UIAlertAction(title: model.displayName, style: .default) { [weak self] _ in
                guard let self else { return }
                self.selectedModel = model
                self.onModelSelected?(model)
                let index = IndexPath(row: 0, section: Section.model.rawValue)
                self.tableView.reloadRows(at: [index], with: .automatic)
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
}

extension MenuViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .model: return 2
        case .history: return conversations.count
        case .account: return 1
        case .none: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch Section(rawValue: indexPath.section) {
        case .model:
            if indexPath.row == 0 {
                if availableModels.isEmpty {
                    cell.textLabel?.text = "모델 불러오는 중..."
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                } else {
                    cell.textLabel?.text = selectedModel.displayName
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                }
            } else {
                guard let toggleCell = tableView.dequeueReusableCell(withIdentifier: "StreamToggleCell", for: indexPath) as? StreamToggleCell else {
                    return UITableViewCell()
                }
                toggleCell.configure(isOn: streamEnabled)
                toggleCell.onToggle = { [weak self] isOn in
                    self?.streamEnabled = isOn
                    self?.onStreamChanged?(isOn)
                }
                return toggleCell
            }
        case .history:
            let convo = conversations[indexPath.row]
            cell.textLabel?.text = convo.title
            let isSelected: Bool
            if currentConversationID == nil {
                isSelected = convo.id == "draft"
            } else {
                isSelected = convo.id == currentConversationID
            }
            cell.accessoryType = isSelected ? .checkmark : .none
            cell.selectionStyle = .default
        case .account:
            cell.textLabel?.text = "로그아웃"
            cell.accessoryType = .none
            cell.selectionStyle = .default
        case .none:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }
}


