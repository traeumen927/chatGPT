import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class LoginViewController: UIViewController {
    private let viewModel: LoginViewModel
    private let disposeBag = DisposeBag()
    private let completion: () -> Void

    // MARK: 로그인버튼
    private lazy var loginButton: GoogleLoginButton = {
        let button = GoogleLoginButton()
        return button
    }()
    
    // MARK: 제목
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = ThemeColor.label1
        label.textAlignment = .center
        label.text = "질문을 남기고, 다시 꺼내보세요."
        return label
    }()
    
    // MARK: 부제
    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = ThemeColor.label2
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "대화를 저장하고, 이전에 나눈 이야기들을 기억하도록 하세요.\n질문 히스토리를 기반으로 GPT가 더 나은 답변을 제공합니다."
        return label
    }()

    init(viewModel: LoginViewModel, completion: @escaping () -> Void) {
        self.viewModel = viewModel
        self.completion = completion
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
        view.backgroundColor = ThemeColor.background1
        
        [self.titleLabel, self.subTitleLabel, self.loginButton].forEach(self.view.addSubview(_:))
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(32)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        self.subTitleLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.titleLabel).offset(48)
            make.leading.trailing.equalToSuperview()
        }
        
        
        self.loginButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-32)
        }
    }

    private func bind() {
        let input = LoginViewModel.Input(loginTap: loginButton.rx.tap.asObservable())
        let output = viewModel.transform(input: input)

        output.loginResult
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] _ in
                self?.completion()
            })
            .disposed(by: disposeBag)
    }
}
