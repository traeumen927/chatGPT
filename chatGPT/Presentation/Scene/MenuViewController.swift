import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MenuViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case history
        case account

        var title: String {
            switch self {
            case .history: return "대화 히스토리"
            case .account: return "계정"
            }
        }
    }

    private enum Item: Hashable {
        case conversation(ConversationSummary)
        case signOut
    }

    private let observeConversationsUseCase: ObserveConversationsUseCase
    private let signOutUseCase: SignOutUseCase
    private let currentConversationID: String?
    private let disposeBag = DisposeBag()



    // 메뉴 닫기용 클로저
    var onClose: (() -> Void)?

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()
  
    private var dataSource: UITableViewDiffableDataSource<Section, Item>!

    init(observeConversationsUseCase: ObserveConversationsUseCase,
         signOutUseCase: SignOutUseCase,
         currentConversationID: String?,
         onClose: (() -> Void)? = nil) {
        self.observeConversationsUseCase = observeConversationsUseCase
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

    }


    private func bind() {
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)
                guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return }
                switch item {
                case .signOut:
                    do {
                        try self.signOutUseCase.execute()
                        self.onClose?()
                    } catch {
                        print("❌ Sign out failed: \(error.localizedDescription)")
                    }
                case .conversation:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    private func load() {
        dataSource = createDataSource()
        observeConversationsUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] list in
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
            case .signOut:
                cell.textLabel?.text = "로그아웃"
                cell.accessoryType = .none
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
        snapshot.appendItems([.signOut], toSection: .account)

        let shouldAnimate = !dataSource.snapshot().itemIdentifiers.isEmpty
        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
}

extension MenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }
}

