import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class StreamToggleCell: UITableViewCell {
    private let toggleSwitch = UISwitch()
    private let disposeBag = DisposeBag()

    var onToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        selectionStyle = .none
        textLabel?.text = "스트림"

        contentView.addSubview(toggleSwitch)
        toggleSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }

    private func bind() {
        toggleSwitch.rx.controlEvent(.valueChanged)
            .withLatestFrom(toggleSwitch.rx.isOn)
            .subscribe(onNext: { [weak self] isOn in
                self?.onToggle?(isOn)
            })
            .disposed(by: disposeBag)
    }

    func configure(isOn: Bool) {
        toggleSwitch.isOn = isOn
    }
}
