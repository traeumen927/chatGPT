import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class PreferenceHistoryViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case status
        case history

        var title: String {
            switch self {
            case .status: return "현재 상태"
            case .history: return "기록"
            }
        }
    }

    private let fetchEventsUseCase: FetchPreferenceEventsUseCase
    private let fetchStatusUseCase: FetchPreferenceStatusUseCase
    private let updateStatusUseCase: UpdatePreferenceStatusUseCase
    private let deleteEventUseCase: DeletePreferenceEventUseCase
    private let deleteStatusUseCase: DeletePreferenceStatusUseCase
    private let disposeBag = DisposeBag()

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let events = BehaviorRelay<[PreferenceEvent]>(value: [])
    private let statuses = BehaviorRelay<[PreferenceStatus]>(value: [])

    init(fetchEventsUseCase: FetchPreferenceEventsUseCase,
         fetchStatusUseCase: FetchPreferenceStatusUseCase,
         updateStatusUseCase: UpdatePreferenceStatusUseCase,
         deleteEventUseCase: DeletePreferenceEventUseCase,
         deleteStatusUseCase: DeletePreferenceStatusUseCase) {
        self.fetchEventsUseCase = fetchEventsUseCase
        self.fetchStatusUseCase = fetchStatusUseCase
        self.updateStatusUseCase = updateStatusUseCase
        self.deleteEventUseCase = deleteEventUseCase
        self.deleteStatusUseCase = deleteStatusUseCase
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bind() {
        Observable.combineLatest(statuses, events)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _, _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)
                guard Section(rawValue: indexPath.section) == .status else { return }
                let status = self.statuses.value[indexPath.row]
                self.showEditAlert(status: status)
            })
            .disposed(by: disposeBag)
    }

    private func load() {
        fetchStatusUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                self?.statuses.accept(items)
            })
            .disposed(by: disposeBag)

        fetchEventsUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                self?.events.accept(items.sorted { $0.timestamp > $1.timestamp })
            })
            .disposed(by: disposeBag)
    }

    private func showEditAlert(status: PreferenceStatus) {
        let alert = UIAlertController(title: "수정", message: nil, preferredStyle: .actionSheet)
        let relations: [PreferenceRelation] = [.like, .dislike, .want, .avoid]
        relations.forEach { relation in
            alert.addAction(UIAlertAction(title: relation.rawValue, style: .default) { [weak self] _ in
                guard var self else { return }
                var updated = status
                updated.currentRelation = relation
                updated.updatedAt = Date().timeIntervalSince1970
                self.updateStatusUseCase.execute(status: updated)
                    .subscribe(onSuccess: { [weak self] in
                        guard let self else { return }
                        if let idx = self.statuses.value.firstIndex(where: { $0.key == updated.key }) {
                            var new = self.statuses.value
                            new[idx] = updated
                            self.statuses.accept(new)
                        }
                    })
                    .disposed(by: self.disposeBag)
            })
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
}

extension PreferenceHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .status: return statuses.value.count
        case .history: return events.value.count
        case .none: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch Section(rawValue: indexPath.section) {
        case .status:
            let item = statuses.value[indexPath.row]
            cell.textLabel?.text = "\(item.key) - \(item.currentRelation.rawValue)"
        case .history:
            let ev = events.value[indexPath.row]
            let date = Date(timeIntervalSince1970: ev.timestamp)
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .short
            cell.textLabel?.text = "\(ev.key) [\(ev.relation.rawValue)] - \(df.string(from: date))"
        case .none:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch Section(rawValue: indexPath.section) {
        case .status:
            let key = statuses.value[indexPath.row].key
            let delete = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completion in
                guard let self else { completion(true); return }
                self.deleteStatusUseCase.execute(key: key)
                    .subscribe(onSuccess: { [weak self] in
                        var items = self?.statuses.value ?? []
                        items.removeAll { $0.key == key }
                        self?.statuses.accept(items)
                    })
                    .disposed(by: self.disposeBag)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        case .history:
            guard let id = events.value[indexPath.row].id else { return nil }
            let delete = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completion in
                guard let self else { completion(true); return }
                self.deleteEventUseCase.execute(eventID: id)
                    .subscribe(onSuccess: { [weak self] in
                        var items = self?.events.value ?? []
                        items.removeAll { $0.id == id }
                        self?.events.accept(items)
                    })
                    .disposed(by: self.disposeBag)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        case .none:
            return nil
        }
    }
}
