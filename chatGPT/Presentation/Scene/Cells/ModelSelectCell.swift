import UIKit
import SnapKit

final class ModelSelectCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let valueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.label, for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        [titleLabel, valueButton].forEach(contentView.addSubview)
        selectionStyle = .default

        titleLabel.font = .systemFont(ofSize: 16)
        valueButton.titleLabel?.font = .systemFont(ofSize: 16)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        valueButton.snp.makeConstraints { make in
            // 32 is roughly the width of disclosure indicator area
            make.trailing.equalToSuperview().inset(32)
            make.centerY.equalToSuperview()
        }
    }

    func configure(title: String, modelName: String, loading: Bool, menu: UIMenu?) {
        titleLabel.text = title
        valueButton.setTitle(loading ? "모델 불러오는 중..." : modelName, for: .normal)
        valueButton.isEnabled = !loading
        valueButton.menu = menu
        valueButton.showsMenuAsPrimaryAction = menu != nil
        accessoryType = (loading || menu == nil) ? .none : .disclosureIndicator
        selectionStyle = loading ? .none : .default
    }

    func showMenu() {
        guard valueButton.menu != nil else { return }
        valueButton.sendActions(for: .touchUpInside)
    }
}
