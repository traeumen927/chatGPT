import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MenuViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case history

        var title: String { "과거 히스토리" }
    }

    private enum Item: Hashable {
        case conversation(ConversationSummary)
    }

    private let fetchConversationsUseCase: FetchConversationsUseCase
    private let signOutUseCase: SignOutUseCase
    private let currentConversationID: String?
    private let disposeBag = DisposeBag()

    private lazy var signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.setTitleColor(ThemeColor.label1, for: .normal)
        return button
    }()

    // 메뉴 닫기용 클로저
    var onClose: (() -> Void)?

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    private var dataSource: UITableViewDiffableDataSource<Section, Item>!

    init(fetchConversationsUseCase: FetchConversationsUseCase,
         signOutUseCase: SignOutUseCase,
         currentConversationID: String?,
         onClose: (() -> Void)? = nil) {
        self.fetchConversationsUseCase = fetchConversationsUseCase
        self.signOutUseCase = signOutUseCase
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
    }

    private func layout() {
        view.backgroundColor = ThemeColor.background1
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 60))
        footerView.addSubview(signOutButton)
        signOutButton.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
            make.height.equalTo(44)
        }
        tableView.tableFooterView = footerView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let footer = tableView.tableFooterView {
            footer.frame.size.width = tableView.frame.width
        }
    }

    private func bind() {
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)

        signOutButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                do {
                    try self.signOutUseCase.execute()
                    self.onClose?()
                } catch {
                    print("❌ Sign out failed: \(error.localizedDescription)")
                }
            })
            .disposed(by: disposeBag)
    }

    private func load() {
        dataSource = createDataSource()
        fetchConversationsUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] list in
                self?.applySnapshot(list)
            })
            .disposed(by: disposeBag)
    }

    private func createDataSource() -> UITableViewDiffableDataSource<Section, Item> {
        let ds = UITableViewDiffableDataSource<Section, Item>(tableView: tableView) { [weak self] tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

            switch item {
            case .conversation(let convo):
                cell.textLabel?.text = convo.title
                let isSelected = convo.id == self?.currentConversationID
                cell.accessoryType = isSelected ? .checkmark : .none
                cell.selectionStyle = .default
            }

            return cell
        }
        tableView.delegate = self
        return ds
    }

    private func applySnapshot(_ items: [ConversationSummary]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(items.map { .conversation($0) }, toSection: .history)

        let shouldAnimate = !dataSource.snapshot().itemIdentifiers.isEmpty
        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
}

extension MenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }
}

