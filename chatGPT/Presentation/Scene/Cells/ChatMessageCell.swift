//
//  ChatMessageCell.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ChatMessageCell: UITableViewCell {

    private var lastHeight: CGFloat = 0

    private var disposeBag = DisposeBag()

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
        view.alignment = .leading
        return view
    }()
    private let attachmentsStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 4
        view.alignment = .leading
        return view
    }()
    private let userImageScrollView = UIScrollView()
    private let userImageStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 8
        return view
    }()
    private var userImageHeightConstraint: Constraint?
    private var messageTopConstraint: Constraint?
    private var stackTopConstraint: Constraint?


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
        backgroundColor = .clear

        bubbleView.clipsToBounds = true

        [userImageScrollView, bubbleView].forEach(contentView.addSubview)
        userImageScrollView.addSubview(userImageStackView)
        [attachmentsStackView, messageView, stackView].forEach(bubbleView.addSubview)

        stackView.isHidden = true
        messageView.isHidden = false

        userImageScrollView.showsHorizontalScrollIndicator = true
        userImageScrollView.isHidden = true
        userImageStackView.axis = .horizontal
        userImageStackView.spacing = 8

        userImageScrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            userImageHeightConstraint = make.height.equalTo(0).constraint
        }

        userImageStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        bubbleView.snp.makeConstraints { make in
            make.top.equalTo(userImageScrollView.snp.bottom).offset(8).priority(999)
            make.bottom.equalToSuperview().inset(8).priority(999)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        attachmentsStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12).priority(999)
        }

        messageView.snp.makeConstraints { make in
            self.messageTopConstraint = make.top.equalTo(attachmentsStackView.snp.bottom).constraint
            make.leading.trailing.equalToSuperview().inset(12).priority(999)
            make.bottom.equalToSuperview().inset(12).priority(999)
        }

        stackView.snp.makeConstraints { make in
            self.stackTopConstraint = make.top.equalTo(attachmentsStackView.snp.bottom).constraint
            make.leading.trailing.equalToSuperview().inset(12).priority(999)
            make.bottom.equalToSuperview().inset(12).priority(999)
        }
    }

    private func bind() {
        // no reactive bindings yet
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
                    textView.snp.makeConstraints { $0.width.equalToSuperview() }
                }
                stackView.addArrangedSubview(attachment.view)
                attachment.view.snp.makeConstraints { $0.width.equalToSuperview() }
                currentLocation = range.location + range.length
            } else if let attachment = value as? HorizontalRuleAttachment {
                if range.location > currentLocation {
                    let textRange = NSRange(location: currentLocation, length: range.location - currentLocation)
                    let textView = makeTextView()
                    textView.attributedText = attributed.attributedSubstring(from: textRange)
                    stackView.addArrangedSubview(textView)
                    textView.snp.makeConstraints { $0.width.equalToSuperview() }
                }
                stackView.addArrangedSubview(attachment.view)
                attachment.view.snp.makeConstraints { $0.width.equalToSuperview() }
                currentLocation = range.location + range.length
            } else if let attachment = value as? TableBlockAttachment {
                if range.location > currentLocation {
                    let textRange = NSRange(location: currentLocation, length: range.location - currentLocation)
                    let textView = makeTextView()
                    textView.attributedText = attributed.attributedSubstring(from: textRange)
                    stackView.addArrangedSubview(textView)
                    textView.snp.makeConstraints { $0.width.equalToSuperview() }
                }
                stackView.addArrangedSubview(attachment.view)
                attachment.view.snp.makeConstraints { $0.width.equalToSuperview() }
                currentLocation = range.location + range.length
            } else if let attachment = value as? RemoteImageAttachment {
                if range.location > currentLocation {
                    let textRange = NSRange(location: currentLocation, length: range.location - currentLocation)
                    let textView = makeTextView()
                    textView.attributedText = attributed.attributedSubstring(from: textRange)
                    stackView.addArrangedSubview(textView)
                    textView.snp.makeConstraints { $0.width.equalToSuperview() }
                }
                stackView.addArrangedSubview(attachment.view)
                attachment.view.snp.makeConstraints { make in
                    make.width.equalToSuperview().multipliedBy(0.65)
                    make.height.equalTo(attachment.view.snp.width)
                }
                currentLocation = range.location + range.length
            } else if let attachment = value as? RemoteImageGroupAttachment {
                if range.location > currentLocation {
                    let textRange = NSRange(location: currentLocation, length: range.location - currentLocation)
                    let textView = makeTextView()
                    textView.attributedText = attributed.attributedSubstring(from: textRange)
                    stackView.addArrangedSubview(textView)
                    textView.snp.makeConstraints { $0.width.equalToSuperview() }
                }
                stackView.addArrangedSubview(attachment.view)
                attachment.view.snp.makeConstraints { make in
                    make.width.equalToSuperview()
                    make.height.equalTo(attachment.view.snp.width).multipliedBy(0.65)
                }
                currentLocation = range.location + range.length
            }
        }

        if currentLocation < attributed.length {
            let remainingRange = NSRange(location: currentLocation, length: attributed.length - currentLocation)
            let textView = makeTextView()
            textView.attributedText = attributed.attributedSubstring(from: remainingRange)
            stackView.addArrangedSubview(textView)
            textView.snp.makeConstraints { $0.width.equalToSuperview() }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageView.text = nil
        messageView.attributedText = nil
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        attachmentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stackView.isHidden = true
        messageView.isHidden = false
        attachmentsStackView.isHidden = true
        messageTopConstraint?.update(offset: 0)
        stackTopConstraint?.update(offset: 0)
        userImageStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        userImageScrollView.isHidden = true
        userImageHeightConstraint?.update(offset: 0)
        disposeBag = DisposeBag()
        lastHeight = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func configure(with message: ChatViewModel.ChatMessage,
                   parser: ParseMarkdownUseCase) {
        attachmentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        userImageStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let urls = message.urls.compactMap { URL(string: $0) }
        let imageExts = ["png","jpg","jpeg","gif","heic","heif","webp"]
        let imageUrls = urls.filter { imageExts.contains($0.pathExtension.lowercased()) }
        let fileUrls = urls.filter { !imageExts.contains($0.pathExtension.lowercased()) }

        if message.type == .user {
            if imageUrls.isEmpty {
                userImageScrollView.isHidden = true
                userImageHeightConstraint?.update(offset: 0)
            } else {
                userImageScrollView.isHidden = false
                userImageHeightConstraint?.update(offset: 80)
                for url in imageUrls {
                    let view = RemoteImageView(url: url)
                    userImageStackView.addArrangedSubview(view)
                    view.snp.makeConstraints { make in
                        make.width.equalTo(80)
                        make.height.equalToSuperview()
                    }
                }
            }

            if fileUrls.isEmpty {
                attachmentsStackView.isHidden = true
                messageTopConstraint?.update(offset: 0)
                stackTopConstraint?.update(offset: 0)
            } else {
                attachmentsStackView.isHidden = false
                messageTopConstraint?.update(offset: 8)
                stackTopConstraint?.update(offset: 8)
                for url in fileUrls {
                    let button = UIButton(type: .system)
                    let image = UIImage(systemName: "doc.fill")
                    button.setImage(image, for: .normal)
                    button.setTitle(" " + url.lastPathComponent, for: .normal)
                    button.contentHorizontalAlignment = .left
                    button.rx.tap.bind { UIApplication.shared.open(url) }.disposed(by: disposeBag)
                    attachmentsStackView.addArrangedSubview(button)
                    button.snp.makeConstraints { $0.width.equalToSuperview() }
                }
            }
        } else {
            userImageScrollView.isHidden = true
            userImageHeightConstraint?.update(offset: 0)
            if urls.isEmpty {
                attachmentsStackView.isHidden = true
                messageTopConstraint?.update(offset: 0)
                stackTopConstraint?.update(offset: 0)
            } else {
                attachmentsStackView.isHidden = false
                messageTopConstraint?.update(offset: 8)
                stackTopConstraint?.update(offset: 8)
                for url in urls {
                    if imageExts.contains(url.pathExtension.lowercased()) {
                        let view = RemoteImageView(url: url)
                        attachmentsStackView.addArrangedSubview(view)
                        view.snp.makeConstraints { make in
                            make.width.equalToSuperview().multipliedBy(0.65)
                            make.height.equalTo(view.snp.width)
                        }
                    } else {
                        let button = UIButton(type: .system)
                        let image = UIImage(systemName: "doc.fill")
                        button.setImage(image, for: .normal)
                        button.setTitle(" " + url.lastPathComponent, for: .normal)
                        button.contentHorizontalAlignment = .left
                        button.rx.tap.bind { UIApplication.shared.open(url) }.disposed(by: disposeBag)
                        attachmentsStackView.addArrangedSubview(button)
                        button.snp.makeConstraints { $0.width.equalToSuperview() }
                    }
                }
            }
        }

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
                make.top.equalTo(userImageScrollView.snp.bottom).offset(8).priority(999)
                make.bottom.equalToSuperview().inset(8).priority(999)
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
                make.top.equalTo(userImageScrollView.snp.bottom).offset(8).priority(999)
                make.bottom.equalToSuperview().inset(8).priority(999)
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
                make.top.equalTo(userImageScrollView.snp.bottom).offset(8).priority(999)
                make.bottom.equalToSuperview().inset(8).priority(999)
                make.leading.equalToSuperview().inset(16)
                make.trailing.lessThanOrEqualToSuperview().inset(UIScreen.main.bounds.width * 0.2)
            }
        }

        layoutIfNeeded()
        let attachmentHeight = attachmentsStackView.isHidden ? 0 : attachmentsStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + 8
        let imageHeight = userImageScrollView.isHidden ? 0 : (userImageHeightConstraint?.layoutConstraints.first?.constant ?? 80) + 8
        if stackView.isHidden {
            messageView.addAttachmentViews()
            lastHeight = messageView.contentSize.height + attachmentHeight + imageHeight
        } else {
            lastHeight = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + attachmentHeight + imageHeight
        }

    }

    @discardableResult
    func update(text: String, parser: ParseMarkdownUseCase) -> Bool {
        if stackView.isHidden {
            messageView.attributedText = parser.execute(markdown: text)
            layoutIfNeeded()
            messageView.addAttachmentViews()
            let attach = attachmentsStackView.isHidden ? 0 : attachmentsStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + 8
            let images = userImageScrollView.isHidden ? 0 : (userImageHeightConstraint?.layoutConstraints.first?.constant ?? 80) + 8
            let newHeight = messageView.contentSize.height + attach + images
            defer { lastHeight = newHeight }
            return newHeight != lastHeight
        } else {
            let attributed = parser.execute(markdown: text)
            buildStack(from: attributed)
            layoutIfNeeded()
            let attach = attachmentsStackView.isHidden ? 0 : attachmentsStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + 8
            let images = userImageScrollView.isHidden ? 0 : (userImageHeightConstraint?.layoutConstraints.first?.constant ?? 80) + 8
            let newHeight = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + attach + images
            defer { lastHeight = newHeight }
            return newHeight != lastHeight
        }
    }

}
