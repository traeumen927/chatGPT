//
//  ChatMessageCell.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import UIKit
import SnapKit

final class ChatMessageCell: UITableViewCell {

    private var lastHeight: CGFloat = 0

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
            make.top.bottom.equalToSuperview().inset(8).priority(999)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12).priority(999)
        }
    }

    func configure(with message: ChatViewModel.ChatMessage) {

        messageLabel.text = message.text


        switch message.type {
        case .user:
            bubbleView.isHidden = false
            bubbleView.backgroundColor = UIColor.systemBlue
            bubbleView.layer.cornerRadius = 16
            messageLabel.textColor = .white
            messageLabel.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(12).priority(999)
            }
            bubbleView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(8).priority(999)
                make.trailing.equalToSuperview().inset(16)
                make.leading.greaterThanOrEqualToSuperview().inset(UIScreen.main.bounds.width * 0.2)
            }

        case .assistant:
            bubbleView.isHidden = false
            bubbleView.backgroundColor = .clear
            bubbleView.layer.cornerRadius = 0
            messageLabel.textColor = .label
            messageLabel.snp.remakeConstraints { make in
                make.edges.equalToSuperview().priority(999)
            }
            bubbleView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(8).priority(999)
                make.leading.trailing.equalToSuperview().inset(16)
            }

        case .error:
            bubbleView.isHidden = false
            bubbleView.backgroundColor = UIColor.systemRed
            bubbleView.layer.cornerRadius = 16
            messageLabel.textColor = .white
            messageLabel.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(12).priority(999)
            }
            bubbleView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(8).priority(999)
                make.leading.equalToSuperview().inset(16)
                make.trailing.lessThanOrEqualToSuperview().inset(UIScreen.main.bounds.width * 0.2)
            }
        }

        layoutIfNeeded()
        lastHeight = messageLabel.bounds.height

    }

    @discardableResult
    func update(text: String) -> Bool {
        messageLabel.text = text
        layoutIfNeeded()
        let newHeight = messageLabel.bounds.height
        defer { lastHeight = newHeight }
        return newHeight != lastHeight
    }
}
