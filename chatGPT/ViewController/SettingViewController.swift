//
//  SettingViewController.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/07.
//

import UIKit
import SnapKit
import RxSwift

class SettingViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    private var viewModel: SettingViewModel!
    
    private var menus:[Section] = [Section]()
    
    private lazy var tablewView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.delegate = self
        view.dataSource = self
        view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        return view
    }()
    
    init(viewModel: SettingViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
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
        self.view.backgroundColor = .systemBackground
        self.title = "Setting"
        
        self.view.addSubview(tablewView)
        
        tablewView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
    }
    
    private func bind() {
        self.viewModel.configure()
        self.viewModel.menuSubject.subscribe(onNext: { [weak self] menus in
            guard let self = self else {return}
            self.menus = menus
            
            DispatchQueue.main.async {
                self.tablewView.reloadData()
            }
        }).disposed(by: disposeBag)
    }
}

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return menus[section].title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return menus.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus[section].options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let menu = menus[indexPath.section].options[indexPath.row]
        
        
        switch menu.self {
        
        case .normalCell(model: let model):
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.selectionStyle = .none
            
            var configuration = cell.defaultContentConfiguration()
            configuration.text = model.title
            configuration.image = UIImage(systemName: model.systemImage)
            configuration.secondaryText = model.subTitle
            
            cell.accessoryView = nil
            cell.contentConfiguration = configuration
            return cell
            
        case .switchCell(model: let model):
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.selectionStyle = .none
            let menuSwitch = UISwitch()
            menuSwitch.isOn = model.isOn
            menuSwitch.rx.controlEvent(.valueChanged).withLatestFrom(menuSwitch.rx.value).subscribe(onNext: { isOn in
                model.handler(isOn)
            }).disposed(by: disposeBag)
            
            var configuration = cell.defaultContentConfiguration()
            configuration.text = model.title
            configuration.image = UIImage(systemName: model.systemImage)
            
            cell.accessoryView = menuSwitch
            cell.contentConfiguration = configuration
            
            
            
            return cell
        }
    }
}
