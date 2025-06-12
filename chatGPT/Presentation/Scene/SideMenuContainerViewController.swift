import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class SideMenuContainerViewController: UIViewController {
    private let contentViewController: UIViewController
    private let menuViewController: UIViewController
    private let menuWidth: CGFloat = 260

    private let disposeBag = DisposeBag()
    private var leadingConstraint: Constraint?
    private var isOpen = false

    private let dimmedView = UIView()

    init(contentViewController: UIViewController, menuViewController: UIViewController) {
        self.contentViewController = contentViewController
        self.menuViewController = menuViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.layout()
        self.bind()
    }

    private func layout() {
        addChild(menuViewController)
        view.addSubview(menuViewController.view)
        menuViewController.didMove(toParent: self)

        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)

        menuViewController.view.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.width.equalTo(menuWidth)
            self.leadingConstraint = make.leading.equalToSuperview().offset(-menuWidth).constraint
        }

        contentViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        dimmedView.alpha = 0
        contentViewController.view.addSubview(dimmedView)
        dimmedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bind() {
        if let nav = contentViewController as? UINavigationController,
           let main = nav.viewControllers.first as? MainViewController {
            main.menuButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.toggleMenu(open: !(self?.isOpen ?? false))
                })
                .disposed(by: disposeBag)
        }

        let edgePan = UIScreenEdgePanGestureRecognizer()
        edgePan.edges = .left
        view.addGestureRecognizer(edgePan)

        edgePan.rx.event
            .subscribe(onNext: { [weak self] gesture in
                guard let self = self else { return }
                let x = gesture.translation(in: self.view).x
                switch gesture.state {
                case .changed:
                    let offset = min(0, max(-self.menuWidth + x, -self.menuWidth))
                    self.leadingConstraint?.update(offset: offset)
                case .ended:
                    let shouldOpen = x > self.menuWidth / 2
                    self.toggleMenu(open: shouldOpen)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)

        let pan = UIPanGestureRecognizer()
        dimmedView.addGestureRecognizer(pan)
        dimmedView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeMenu)))

        pan.rx.event
            .subscribe(onNext: { [weak self] gesture in
                guard let self = self else { return }
                let x = gesture.translation(in: self.view).x
                switch gesture.state {
                case .changed:
                    let offset = min(0, max(x, -self.menuWidth))
                    self.leadingConstraint?.update(offset: offset)
                case .ended:
                    let shouldClose = x < -self.menuWidth / 2
                    self.toggleMenu(open: !shouldClose)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    @objc private func closeMenu() {
        toggleMenu(open: false)
    }

    private func toggleMenu(open: Bool) {
        isOpen = open
        leadingConstraint?.update(offset: open ? 0 : -menuWidth)
        UIView.animate(withDuration: 0.3) {
            self.dimmedView.alpha = open ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }
}
