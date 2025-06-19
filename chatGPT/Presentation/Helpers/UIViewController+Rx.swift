import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIViewController {
    var viewDidLoad: ControlEvent<Void> {
        let source = methodInvoked(#selector(UIViewController.viewDidLoad))
            .map { _ in }
        return ControlEvent(events: source)
    }
}
