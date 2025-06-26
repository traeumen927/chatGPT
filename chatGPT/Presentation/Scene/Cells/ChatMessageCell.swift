//
//  ChatMessageCell.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import UIKit
import SnapKit

final class ChatMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textColor = .white
        label.lineBreakMode = .byCharWrapping

        return label
    }()


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        selectionStyle = .none
        backgroundColor = .clear

        bubbleView.clipsToBounds = true

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)

        bubbleView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }

    func configure(with message: ChatViewModel.ChatMessage) {

        self.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)

        messageLabel.text = message.text
        

        switch message.type {
        case .user:
            bubbleView.isHidden = false
            bubbleView.backgroundColor = UIColor.systemBlue
            bubbleView.layer.cornerRadius = 16
            messageLabel.textColor = .white
            messageLabel.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(12)
            }
            bubbleView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(8)
                make.trailing.equalToSuperview().inset(16)
                make.leading.greaterThanOrEqualToSuperview().inset(UIScreen.main.bounds.width * 0.2)
            }

        case .assistant:
            bubbleView.isHidden = false
            bubbleView.backgroundColor = .clear
            bubbleView.layer.cornerRadius = 0
            messageLabel.textColor = .label
            messageLabel.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            bubbleView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(8)
                make.leading.trailing.equalToSuperview().inset(16)
            }

        case .error:
            bubbleView.isHidden = false
            bubbleView.backgroundColor = UIColor.systemRed
            bubbleView.layer.cornerRadius = 16
            messageLabel.textColor = .white
            messageLabel.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(12)
            }
            bubbleView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(8)
                make.leading.equalToSuperview().inset(16)
                make.trailing.lessThanOrEqualToSuperview().inset(UIScreen.main.bounds.width * 0.2)
            }
        }

    }

    func update(text: String) {
        messageLabel.text = text
        layoutIfNeeded()
    }
}
