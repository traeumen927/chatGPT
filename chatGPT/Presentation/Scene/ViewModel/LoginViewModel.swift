import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

final class LoginViewModel {
    struct Input {
        let loginTap: Observable<Void>
    }

    struct Output {
        let loginResult: Observable<AuthDataResult>
    }

    func transform(input: Input) -> Output {
        let result = input.loginTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .flatMapLatest { [weak self] _ -> Observable<AuthDataResult> in
                guard let self = self else { return .empty() }
                return self.signInWithGoogle()
                    .catch { _ in .empty() }
            }
        return Output(loginResult: result)
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

enum LoginError: Error {
    case missingClientID
    case missingRootViewController
    case missingToken
    case firebaseAuthFailed
}
