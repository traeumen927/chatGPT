import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ChatListViewController: UIViewController {
    private let viewModel: ChatListViewModel
    private let disposeBag = DisposeBag()
    var onSelectChat: ((Chat) -> Void)?
    private let tableView = UITableView()

    init(viewModel: ChatListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout()
        bind()
    }

    private func layout() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bind() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        let input = ChatListViewModel.Input(viewDidLoad: rx.viewDidLoad.asObservable())
        let output = viewModel.transform(input: input)

        output.chats
            .drive(tableView.rx.items(cellIdentifier: "Cell")) { _, chat, cell in
                cell.textLabel?.text = chat.title
            }
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(Chat.self)
            .subscribe(onNext: { [weak self] chat in
                self?.onSelectChat?(chat)
            })
            .disposed(by: disposeBag)
    }
}
