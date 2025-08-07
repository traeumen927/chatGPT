import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxRelay

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

    private let viewModel: MenuViewModel
    private let disposeBag = DisposeBag()

    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.setTitleColor(ThemeColor.negative, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        return button
    }()

    // 메뉴 닫기용 클로저
    var onClose: (() -> Void)?
    var onConversationSelected: ((String?) -> Void)?
    var onConversationDeleted: ((String) -> Void)?

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.register(ModelSelectCell.self, forCellReuseIdentifier: "ModelSelectCell")
        tv.register(StreamToggleCell.self, forCellReuseIdentifier: "StreamToggleCell")
        return tv
    }()

    var onModelSelected: ((OpenAIModel) -> Void)?
    var onStreamChanged: ((Bool) -> Void)?

    init(viewModel: MenuViewModel, onClose: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout()
        bind()
        viewModel.load()
        viewModel.loadModels()
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
                    let convo = self.viewModel.conversations.value[indexPath.row]
                    self.viewModel.selectConversation(id: convo.id)
                    self.onConversationSelected?(self.viewModel.currentConversationID)
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
                    try self.viewModel.signOut()
                    self.onClose?()
                } catch {
                    // ignore sign-out failure
                }
            }
            .disposed(by: disposeBag)

        viewModel.conversations
            .observe(on: MainScheduler.instance)
            .bind { [weak self] _ in
                self?.tableView.reloadData()
            }
            .disposed(by: disposeBag)

        viewModel.availableModels
            .observe(on: MainScheduler.instance)
            .bind { [weak self] _ in
                guard let self else { return }
                let index = IndexSet(integer: Section.setting.rawValue)
                self.tableView.reloadSections(index, with: .none)
            }
            .disposed(by: disposeBag)
    }

    private func makeModelMenu() -> UIMenu? {
        let models = viewModel.availableModels.value
        guard !models.isEmpty else { return nil }
        let actions = models.map { model in
            UIAction(title: model.displayName, state: model.modelId == viewModel.selectedModel.value.id ? .on : .off) { [weak self] _ in
                guard let self else { return }
                self.viewModel.selectedModel.accept(model.openAIModel)
                self.onModelSelected?(model.openAIModel)
                let index = IndexPath(row: 0, section: Section.setting.rawValue)
                self.tableView.reloadRows(at: [index], with: .none)
            }
        }
        return UIMenu(title: "", options: .displayInline, children: actions)
    }

    private func showEditAlert(convo: ConversationSummary) {
        let alert = UIAlertController(title: "제목 수정", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = convo.title
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "저장", style: .default) { [weak self, weak alert] _ in
            guard let self, let title = alert?.textFields?.first?.text, !title.isEmpty else { return }
            self.viewModel.updateTitle(id: convo.id, title: title)
        })
        present(alert, animated: true)
    }

    private func deleteConversation(id: String) {
        viewModel.deleteConversation(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] wasCurrent in
                guard let self else { return }
                if wasCurrent {
                    self.onConversationDeleted?(id)
                }
            })
            .disposed(by: disposeBag)
    }
}

extension MenuViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .setting: return 2
        case .history: return viewModel.conversations.value.count
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
                let name = viewModel.availableModels.value.first { $0.modelId == viewModel.selectedModel.value.id }?.displayName ?? viewModel.selectedModel.value.displayName
                modelCell.configure(title: "모델", modelName: name, loading: viewModel.availableModels.value.isEmpty, menu: menu)
                return modelCell
            } else {
                guard let toggleCell = tableView.dequeueReusableCell(withIdentifier: "StreamToggleCell", for: indexPath) as? StreamToggleCell else {
                    return UITableViewCell()
                }
                toggleCell.configure(isOn: viewModel.streamEnabled.value)
                toggleCell.onToggle = { [weak self] isOn in
                    guard let self else { return }
                    self.viewModel.streamEnabled.accept(isOn)
                    self.onStreamChanged?(isOn)
                }
                return toggleCell
            }
        case .history:
            let convo = viewModel.conversations.value[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = convo.title
            let isSelected: Bool
            if viewModel.currentConversationID == nil {
                isSelected = convo.id == "draft"
            } else {
                isSelected = convo.id == viewModel.currentConversationID
            }
            cell.accessoryType = isSelected ? .checkmark : .none
            cell.selectionStyle = .default
            return cell
        case .none:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .setting:
            return section.title
        case .history:
            let hasItem = !viewModel.conversations.value.isEmpty
            return hasItem ? section.title : nil
        }
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

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard Section(rawValue: indexPath.section) == .history else { return nil }
        let convo = viewModel.conversations.value[indexPath.row]
        guard convo.id != "draft" else { return nil }

        let edit = UIContextualAction(style: .normal, title: "수정") { [weak self] _, _, completion in
            self?.showEditAlert(convo: convo)
            completion(true)
        }
        edit.backgroundColor = ThemeColor.positive

        let delete = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completion in
            self?.deleteConversation(id: convo.id)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
}
