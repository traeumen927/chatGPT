import UIKit
import SnapKit

final class ModelSelectCell: UITableViewCell {
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
        contentView.addSubview(valueButton)
        selectionStyle = .default

        textLabel?.font = .systemFont(ofSize: 16)
        valueButton.titleLabel?.font = .systemFont(ofSize: 16)

        valueButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(8)
        }
    }

    func configure(title: String, modelName: String, loading: Bool, menu: UIMenu?) {
        textLabel?.text = title
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
