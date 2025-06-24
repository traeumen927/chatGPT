import UIKit
import SnapKit

final class ConversationCell: UITableViewCell {
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func layout() {
        selectionStyle = .none
        titleLabel.textColor = ThemeColor.label1
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    func configure(with conversation: ConversationSummary, selected: Bool) {
        titleLabel.text = conversation.title
        accessoryType = selected ? .checkmark : .none
    }
}
