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

    private var bubbleLeading: Constraint!
    private var bubbleTrailing: Constraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        bubbleView.layer.cornerRadius = 16
        bubbleView.clipsToBounds = true

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)

        bubbleView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            self.bubbleLeading = make.leading.equalToSuperview().inset(16).constraint
            self.bubbleTrailing = make.trailing.equalToSuperview().inset(16).constraint
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
            bubbleView.backgroundColor = UIColor.systemBlue
            bubbleLeading.deactivate()
            bubbleTrailing.activate()

        case .assistant:
            bubbleView.backgroundColor = UIColor.systemGreen
            bubbleTrailing.deactivate()
            bubbleLeading.activate()

        case .error:
            bubbleView.backgroundColor = UIColor.systemRed
            bubbleTrailing.deactivate()
            bubbleLeading.activate()
        }
        
        self.bubbleView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)

            switch message.type {
            case .user:
                make.trailing.equalToSuperview().inset(16)
                make.leading.greaterThanOrEqualToSuperview().inset(UIScreen.main.bounds.width * 0.2)
            case .assistant, .error:
                make.leading.equalToSuperview().inset(16)
                make.trailing.lessThanOrEqualToSuperview().inset(UIScreen.main.bounds.width * 0.2)
            }
        }

    }
}
