import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MenuViewController: UIViewController {
    private let disposeBag = DisposeBag()

    private lazy var tableView = UITableView(frame: .zero, style: .plain)
    private let items = Observable.just(["Settings", "About"])

    override func viewDidLoad() {
        super.viewDidLoad()
        self.layout()
        self.bind()
    }

    private func layout() {
        view.backgroundColor = ThemeColor.background1
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    private func bind() {
        items.bind(to: tableView.rx.items(cellIdentifier: "cell")) { _, item, cell in
            cell.textLabel?.text = item
        }.disposed(by: disposeBag)
    }
}
