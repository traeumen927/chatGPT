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

    private let observeConversationsUseCase: ObserveConversationsUseCase
    private let signOutUseCase: SignOutUseCase
    private let fetchModelsUseCase: FetchAvailableModelsUseCase
    private let currentConversationID: String?
    private let disposeBag = DisposeBag()



    // 메뉴 닫기용 클로저
    var onClose: (() -> Void)?

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()
  

    var onModelSelected: ((OpenAIModel) -> Void)?

    init(observeConversationsUseCase: ObserveConversationsUseCase,
         signOutUseCase: SignOutUseCase,
         fetchModelsUseCase: FetchAvailableModelsUseCase,
         selectedModel: OpenAIModel,
         currentConversationID: String?,
         onClose: (() -> Void)? = nil) {
        self.observeConversationsUseCase = observeConversationsUseCase
        self.signOutUseCase = signOutUseCase
        self.fetchModelsUseCase = fetchModelsUseCase
        self.selectedModel = selectedModel
        self.currentConversationID = currentConversationID
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
                    self.presentModelSelector()
                case .account:
                    do {
                        try self.signOutUseCase.execute()
                        self.onClose?()
                    } catch {
                        print("❌ Sign out failed: \(error.localizedDescription)")
                    }
                case .history, .none:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    private func load() {
        observeConversationsUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] list in
                self?.conversations = list
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    private func loadModels() {
        fetchModelsUseCase.execute { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let models):
                self.availableModels = models
            case .failure(let error):
                print("❌ 모델 로딩 실패: \(error.localizedDescription)")
            }
        }
    }

    private func presentModelSelector() {
        guard !availableModels.isEmpty else { return }
        let picker = ModelPickerViewController(models: availableModels, selected: selectedModel)
        picker.onSelect = { [weak self] model in
            guard let self else { return }
            self.selectedModel = model
            self.onModelSelected?(model)
            let index = IndexPath(row: 0, section: Section.model.rawValue)
            self.tableView.reloadRows(at: [index], with: .automatic)
        }
        picker.modalPresentationStyle = .pageSheet
        present(picker, animated: true)
    }

}

extension MenuViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .model: return 1
        case .history: return conversations.count
        case .account: return 1
        case .none: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch Section(rawValue: indexPath.section) {
        case .model:
            cell.textLabel?.text = selectedModel.displayName
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case .history:
            let convo = conversations[indexPath.row]
            cell.textLabel?.text = convo.title
            let isSelected = convo.id == currentConversationID
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

