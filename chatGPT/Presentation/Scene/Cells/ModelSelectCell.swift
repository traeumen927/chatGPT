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
    private let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        [titleLabel, valueButton, arrowImageView].forEach(contentView.addSubview)
        selectionStyle = .default

        titleLabel.font = .systemFont(ofSize: 16)
        valueButton.titleLabel?.font = .systemFont(ofSize: 16)
        arrowImageView.tintColor = .systemGray3

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }
        valueButton.snp.makeConstraints { make in
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
        }
    }

    func configure(title: String, modelName: String, loading: Bool, menu: UIMenu?) {
        titleLabel.text = title
        valueButton.setTitle(loading ? "모델 불러오는 중..." : modelName, for: .normal)
        valueButton.isEnabled = !loading
        valueButton.menu = menu
        valueButton.showsMenuAsPrimaryAction = menu != nil
        arrowImageView.isHidden = loading || menu == nil
        selectionStyle = loading ? .none : .default
    }

    func showMenu() {
        guard valueButton.menu != nil else { return }
        valueButton.sendActions(for: .touchUpInside)
    }
}
