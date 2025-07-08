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
    private let messageView: UITextView = {
        let view = UITextView()
        view.font = .systemFont(ofSize: 16)
        view.isEditable = false
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.dataDetectorTypes = [.link]
        view.textColor = .label
        return view
    }()
    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 8
        return view
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
        bubbleView.addSubview(messageView)
        bubbleView.addSubview(stackView)

        stackView.isHidden = true
        messageView.isHidden = false

        bubbleView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8).priority(999)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        messageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12).priority(999)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12).priority(999)
        }
    }

    private func makeTextView() -> UITextView {
        let view = UITextView()
        view.font = .systemFont(ofSize: 16)
        view.isEditable = false
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.dataDetectorTypes = [.link]
        view.textColor = .label
        return view
    }

    private func buildStack(from attributed: NSAttributedString) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let fullRange = NSRange(location: 0, length: attributed.length)
        var currentLocation = 0
        attributed.enumerateAttribute(.attachment, in: fullRange) { value, range, _ in
            if let attachment = value as? CodeBlockAttachment {
                if range.location > currentLocation {
                    let textRange = NSRange(location: currentLocation, length: range.location - currentLocation)
                    let textView = makeTextView()
                    textView.attributedText = attributed.attributedSubstring(from: textRange)
                    stackView.addArrangedSubview(textView)
                }
                stackView.addArrangedSubview(attachment.view)
                currentLocation = range.location + range.length
            } else if let attachment = value as? HorizontalRuleAttachment {
                if range.location > currentLocation {
                    let textRange = NSRange(location: currentLocation, length: range.location - currentLocation)
                    let textView = makeTextView()
                    textView.attributedText = attributed.attributedSubstring(from: textRange)
                    stackView.addArrangedSubview(textView)
                }
                stackView.addArrangedSubview(attachment.view)
                currentLocation = range.location + range.length
            } else if let attachment = value as? TableBlockAttachment {
                if range.location > currentLocation {
                    let textRange = NSRange(location: currentLocation, length: range.location - currentLocation)
                    let textView = makeTextView()
                    textView.attributedText = attributed.attributedSubstring(from: textRange)
                    stackView.addArrangedSubview(textView)
                }
                stackView.addArrangedSubview(attachment.view)
                currentLocation = range.location + range.length
            }
        }

        if currentLocation < attributed.length {
            let remainingRange = NSRange(location: currentLocation, length: attributed.length - currentLocation)
            let textView = makeTextView()
            textView.attributedText = attributed.attributedSubstring(from: remainingRange)
            stackView.addArrangedSubview(textView)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageView.text = nil
        messageView.attributedText = nil
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stackView.isHidden = true
        messageView.isHidden = false
        lastHeight = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func configure(with message: ChatViewModel.ChatMessage,
                   parser: ParseMarkdownUseCase) {

        switch message.type {
        case .assistant:
            let attributed = parser.execute(markdown: message.text)
            buildStack(from: attributed)
            stackView.isHidden = false
            messageView.isHidden = true
        default:
            messageView.text = message.text
            messageView.font = .systemFont(ofSize: 16)
            stackView.isHidden = true
            messageView.isHidden = false
        }

        switch message.type {
        case .user:
            bubbleView.isHidden = false
            bubbleView.backgroundColor = UIColor.systemBlue
            bubbleView.layer.cornerRadius = 16
            messageView.textColor = .white
            messageView.snp.remakeConstraints { make in
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
            messageView.textColor = .label
            stackView.snp.remakeConstraints { make in
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
            messageView.textColor = .white
            messageView.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(12).priority(999)
            }
            bubbleView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(8).priority(999)
                make.leading.equalToSuperview().inset(16)
                make.trailing.lessThanOrEqualToSuperview().inset(UIScreen.main.bounds.width * 0.2)
            }
        }

        layoutIfNeeded()
        if stackView.isHidden {
            messageView.addAttachmentViews()
            lastHeight = messageView.contentSize.height
        } else {
            lastHeight = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        }

    }

    @discardableResult
    func update(text: String,
                parser: ParseMarkdownUseCase,
                streaming: Bool = false) -> Bool {
        if streaming {
            messageView.text = text
            stackView.isHidden = true
            messageView.isHidden = false
            layoutIfNeeded()
            let newHeight = messageView.contentSize.height
            defer { lastHeight = newHeight }
            return newHeight != lastHeight
        }

        if stackView.isHidden {
            messageView.attributedText = parser.execute(markdown: text)
            layoutIfNeeded()
            messageView.addAttachmentViews()
            let newHeight = messageView.contentSize.height
            defer { lastHeight = newHeight }
            return newHeight != lastHeight
        } else {
            let attributed = parser.execute(markdown: text)
            buildStack(from: attributed)
            layoutIfNeeded()
            let newHeight = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            defer { lastHeight = newHeight }
            return newHeight != lastHeight
        }
    }

}
