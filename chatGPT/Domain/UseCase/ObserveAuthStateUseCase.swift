import RxSwift

final class ObserveAuthStateUseCase {
    private let repository: AuthRepository
    init(repository: AuthRepository) { self.repository = repository }
    func execute() -> Observable<AuthUser?> {
        repository.observeAuthState()
            .distinctUntilChanged { $0?.uid == $1?.uid }
    }
}
