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

    private let pickerContainer = UIView()
    private let toolbar = UIToolbar()
    private let pickerView = UIPickerView()
  

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
        [tableView, pickerContainer].forEach(view.addSubview)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        pickerContainer.isHidden = true
        pickerContainer.backgroundColor = ThemeColor.background1
        pickerContainer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        pickerContainer.addSubview(toolbar)
        pickerContainer.addSubview(pickerView)

        toolbar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        pickerView.snp.makeConstraints { make in
            make.top.equalTo(toolbar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(216)
        }

        let cancel = UIBarButtonItem(title: "취소", style: .plain, target: nil, action: nil)
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "선택", style: .done, target: nil, action: nil)
        toolbar.setItems([cancel, flex, done], animated: false)

        pickerView.dataSource = self
        pickerView.delegate = self

        cancel.rx.tap
            .bind { [weak self] in self?.hidePicker() }
            .disposed(by: disposeBag)

        done.rx.tap
            .bind { [weak self] in self?.confirmModelSelection() }
            .disposed(by: disposeBag)
    }


    private func bind() {
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)

                switch Section(rawValue: indexPath.section) {
                case .model:
                    self.showPicker()
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

    private func showPicker() {
        guard !availableModels.isEmpty else { return }
        if let index = availableModels.firstIndex(of: selectedModel) {
            pickerView.selectRow(index, inComponent: 0, animated: false)
        }
        pickerContainer.isHidden = false
    }

    private func hidePicker() {
        pickerContainer.isHidden = true
    }

    private func confirmModelSelection() {
        let index = pickerView.selectedRow(inComponent: 0)
        selectedModel = availableModels[index]
        onModelSelected?(selectedModel)
        let row = IndexPath(row: 0, section: Section.model.rawValue)
        tableView.reloadRows(at: [row], with: .automatic)
        hidePicker()
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

extension MenuViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        availableModels.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        availableModels[row].displayName
    }
}

