import UIKit
import SnapKit
import RxSwift
import RxCocoa
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

enum LoginError: Error {
    case missingClientID
    case missingRootViewController
    case missingToken
    case firebaseAuthFailed
}

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
                .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
                .flatMapLatest { [weak self] _ -> Observable<AuthDataResult> in
                    guard let self = self else { return .empty() }
                    print("버튼눌림")
                    return self.signInWithGoogle()
                        .catch { error in
                            print("❌ 로그인 에러 발생: \(error.localizedDescription)")
                            return .empty() // ✅ 에러로 끊지 않고 스트림 유지
                        }
                }
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.completion()
                })
                .disposed(by: disposeBag)
    }

    private func signInWithGoogle() -> Observable<AuthDataResult> {
        return Observable.create { observer in
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                observer.onError(LoginError.missingClientID)
                return Disposables.create()
            }

            let scenes = UIApplication.shared.connectedScenes
            guard let windowScene = scenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                observer.onError(LoginError.missingRootViewController)
                return Disposables.create()
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            
            GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
                if let error = error {
                    observer.onError(error)
                    return
                }

                guard let idToken = result?.user.idToken?.tokenString,
                      let accessToken = result?.user.accessToken.tokenString else {
                    observer.onError(LoginError.missingToken)
                    return
                }

                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        observer.onError(error)
                    } else if let authResult = authResult {
                        observer.onNext(authResult)
                        observer.onCompleted()
                    } else {
                        observer.onError(LoginError.firebaseAuthFailed)
                    }
                }
            }
            return Disposables.create()
        }
    }
}
