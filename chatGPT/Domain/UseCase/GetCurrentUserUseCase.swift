import Foundation

final class GetCurrentUserUseCase {
    private let repository: AuthRepository
    init(repository: AuthRepository) { self.repository = repository }
    func execute() -> AuthUser? { repository.currentUser() }
}
