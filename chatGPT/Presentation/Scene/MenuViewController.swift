import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MenuViewController: UIViewController {
    private let fetchConversationsUseCase: FetchConversationsUseCase
    private let signOutUseCase: SignOutUseCase
    private let currentConversationID: String?
    private let disposeBag = DisposeBag()

    // 메뉴 닫기용 클로저
    var onClose: (() -> Void)?

    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.register(ConversationCell.self, forCellReuseIdentifier: "ConversationCell")
        tv.tableFooterView = footerView
        return tv
    }()

    private lazy var footerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 60))
        view.addSubview(signOutButton)
        signOutButton.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        return view
    }()

    private lazy var signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.setTitleColor(ThemeColor.label1, for: .normal)
        return button
    }()

    private var dataSource: UITableViewDiffableDataSource<Int, ConversationSummary>!

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
    }

    private func bind() {
        signOutButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
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

    private func createDataSource() -> UITableViewDiffableDataSource<Int, ConversationSummary> {
        UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as! ConversationCell
            let isSelected = item.id == self?.currentConversationID
            cell.configure(with: item, selected: isSelected)
            return cell
        }
    }

    private func applySnapshot(_ items: [ConversationSummary]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ConversationSummary>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

