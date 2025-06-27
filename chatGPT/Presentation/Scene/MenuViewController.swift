import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MenuViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case setting
        case history

        var title: String {
            switch self {
            case .setting: return "설정"
            case .history: return "지난 대화"
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

    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.setTitleColor(ThemeColor.nagative, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        return button
    }()



    // 메뉴 닫기용 클로저
    var onClose: (() -> Void)?
    var onConversationSelected: ((String?) -> Void)?

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.register(ModelSelectCell.self, forCellReuseIdentifier: "ModelSelectCell")
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
                self.tableView.deselectRow(at: indexPath, animated: false)

                switch Section(rawValue: indexPath.section) {
                case .setting:
                    if indexPath.row == 0 {
                        if let cell = self.tableView.cellForRow(at: indexPath) as? ModelSelectCell {
                            cell.showMenu()
                        }
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

        logoutButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .bind { [weak self] in
                guard let self else { return }
                do {
                    try self.signOutUseCase.execute()
                    self.onClose?()
                } catch {
                    print("❌ Sign out failed: \(error.localizedDescription)")
                }
            }
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
                let index = IndexSet(integer: Section.setting.rawValue)
                self.tableView.reloadSections(index, with: .none)
            case .failure(let error):
                print("❌ 모델 로딩 실패: \(error.localizedDescription)")
            }
        }
    }

    private func makeModelMenu() -> UIMenu? {
        guard !availableModels.isEmpty else { return nil }
        let actions = availableModels.map { model in
            UIAction(title: model.displayName, state: model == selectedModel ? .on : .off) { [weak self] _ in
                guard let self else { return }
                self.selectedModel = model
                self.onModelSelected?(model)
                let index = IndexPath(row: 0, section: Section.setting.rawValue)
                self.tableView.reloadRows(at: [index], with: .none)
            }
        }
        return UIMenu(title: "", options: .displayInline, children: actions)
    }

}

extension MenuViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .setting: return 2
        case .history: return conversations.count
        case .none: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .setting:
            if indexPath.row == 0 {
                guard let modelCell = tableView.dequeueReusableCell(withIdentifier: "ModelSelectCell", for: indexPath) as? ModelSelectCell else {
                    return UITableViewCell()
                }
                let menu = makeModelMenu()
                modelCell.configure(title: "모델", modelName: selectedModel.displayName, loading: availableModels.isEmpty, menu: menu)
                return modelCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = convo.title
            let isSelected: Bool
            if currentConversationID == nil {
                isSelected = convo.id == "draft"
            } else {
                isSelected = convo.id == currentConversationID
            }
            cell.accessoryType = isSelected ? .checkmark : .none
            cell.selectionStyle = .default
            return cell
        case .none:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard Section(rawValue: section) == .setting else { return nil }
        let footer = UIView()
        footer.addSubview(logoutButton)
        logoutButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        Section(rawValue: section) == .setting ? 40 : .leastNormalMagnitude
    }
}


