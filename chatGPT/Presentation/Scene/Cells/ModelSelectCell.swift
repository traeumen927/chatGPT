import UIKit
import SnapKit

final class ModelSelectCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        [titleLabel, valueLabel, arrowImageView].forEach(contentView.addSubview)
        selectionStyle = .default

        titleLabel.font = .systemFont(ofSize: 16)
        valueLabel.font = .systemFont(ofSize: 16)
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
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
        }
    }

    func configure(title: String, modelName: String, loading: Bool) {
        titleLabel.text = title
        valueLabel.text = loading ? "모델 불러오는 중..." : modelName
        arrowImageView.isHidden = loading
        selectionStyle = loading ? .none : .default
    }
}
