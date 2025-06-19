import UIKit
import SnapKit
import RxSwift
import RxCocoa
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

final class LoginViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let completion: () -> Void

    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = ThemeColor.positive
        button.setTitle("Google 로그인", for: .normal)
        button.setTitleColor(ThemeColor.label3, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()

    init(completion: @escaping () -> Void) {
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
        view.addSubview(loginButton)

        loginButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalTo(200)
        }
    }

    private func bind() {
        loginButton.rx.tap
            .flatMapLatest { [weak self] _ -> Observable<AuthDataResult> in
                guard let self = self else { return .empty() }
                return self.signInWithGoogle()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.completion()
            })
            .disposed(by: disposeBag)
    }

    private func signInWithGoogle() -> Observable<AuthDataResult> {
        Observable.create { observer in
            guard
                let clientID = FirebaseApp.app()?.options.clientID,
                let window = UIApplication.shared.windows.first,
                let root = window.rootViewController
            else {
                observer.onCompleted()
                return Disposables.create()
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            GIDSignIn.sharedInstance.signIn(withPresenting: root) { result, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                guard
                    let idToken = result?.user.idToken?.tokenString,
                    let accessToken = result?.user.accessToken.tokenString
                else {
                    observer.onError(NSError(domain: "Login", code: -1))
                    return
                }
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        observer.onError(error)
                    } else if let authResult = authResult {
                        observer.onNext(authResult)
                        observer.onCompleted()
                    }
                }
            }
            return Disposables.create()
        }
    }
}
