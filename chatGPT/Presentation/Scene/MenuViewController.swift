import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MenuViewController: UIViewController {
    private let signOutUseCase: SignOutUseCase
    private let disposeBag = DisposeBag()

    private lazy var signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.setTitleColor(ThemeColor.label1, for: .normal)
        return button
    }()

    init(signOutUseCase: SignOutUseCase) {
        self.signOutUseCase = signOutUseCase
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout()
        bind()
    }

    private func layout() {
        view.backgroundColor = ThemeColor.background1
        view.addSubview(signOutButton)
        signOutButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
    }

    private func bind() {
        signOutButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                do {
                    try self.signOutUseCase.execute()
                    self.dismiss(animated: true)
                } catch {
                    print("❌ Sign out failed: \(error.localizedDescription)")
                }
            })
            .disposed(by: disposeBag)
    }
}

