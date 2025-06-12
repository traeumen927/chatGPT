import UIKit
import RxSwift
import RxCocoa

final class MainViewController: UIViewController {
    let menuButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal"), style: .plain, target: nil, action: nil)
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.layout()
        self.bind()
    }

    private func layout() {
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = menuButton
    }

    private func bind() {
        // add bindings later if needed
    }
}
