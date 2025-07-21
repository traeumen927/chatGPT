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
    private let attachmentsImageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.isHidden = true
        return view
    }()
    private var attachmentsImageHeightConstraint: Constraint?
    private var attachmentsImageDisposeBag = DisposeBag()
    private let userImageCollectionView: UICollectionView = {
        let layout = TrailingFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()
    private var userImageHeightConstraint: Constraint?
    private var userImageDisposeBag = DisposeBag()
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

        [userImageCollectionView, bubbleView].forEach(contentView.addSubview)
        [attachmentsStackView, messageView, stackView].forEach(bubbleView.addSubview)

        stackView.isHidden = true
        messageView.isHidden = false

        userImageCollectionView.showsHorizontalScrollIndicator = true
        userImageCollectionView.register(RemoteImageCollectionCell.self, forCellWithReuseIdentifier: "RemoteImageCollectionCell")

        userImageCollectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            userImageHeightConstraint = make.height.equalTo(0).constraint
        }

        bubbleView.snp.makeConstraints { make in
            make.top.equalTo(userImageCollectionView.snp.bottom).offset(8).priority(999)
            make.bottom.equalToSuperview().inset(8).priority(999)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        attachmentsStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12).priority(999)
        }

        attachmentsStackView.addArrangedSubview(attachmentsImageCollectionView)
        attachmentsImageCollectionView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            attachmentsImageHeightConstraint = make.height.equalTo(0).constraint
        }
        attachmentsImageCollectionView.register(RemoteImageCollectionCell.self, forCellWithReuseIdentifier: "RemoteImageCollectionCell")

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
        userImageCollectionView.rx.setDelegate(self).disposed(by: disposeBag)
        userImageCollectionView.rx.observe(CGSize.self, "contentSize")
            .compactMap { $0 }
            .distinctUntilChanged { $0 == $1 }
            .bind { [weak self] size in
                self?.userImageHeightConstraint?.update(offset: size.height)
            }
            .disposed(by: disposeBag)

        attachmentsImageCollectionView.rx.setDelegate(self).disposed(by: disposeBag)
        attachmentsImageCollectionView.rx.observe(CGSize.self, "contentSize")
            .compactMap { $0 }
            .distinctUntilChanged { $0 == $1 }
            .bind { [weak self] size in
                self?.attachmentsImageHeightConstraint?.update(offset: size.height)
            }
            .disposed(by: disposeBag)
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
        attachmentsImageCollectionView.reloadData()
        stackView.isHidden = true
        messageView.isHidden = false
        attachmentsStackView.isHidden = true
        messageTopConstraint?.update(offset: 0)
        stackTopConstraint?.update(offset: 0)
        userImageCollectionView.isHidden = true
        userImageHeightConstraint?.update(offset: 0)
        attachmentsImageHeightConstraint?.update(offset: 0)
        disposeBag = DisposeBag()
        userImageDisposeBag = DisposeBag()
        attachmentsImageDisposeBag = DisposeBag()
        lastHeight = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func configure(with message: ChatViewModel.ChatMessage,
                   parser: ParseMarkdownUseCase) {
        attachmentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        userImageCollectionView.reloadData()

        let urls = message.urls.compactMap { URL(string: $0) }
        let imageExts = ["png","jpg","jpeg","gif","heic","heif","webp"]
        let imageUrls = urls.filter { imageExts.contains($0.pathExtension.lowercased()) }
        let fileUrls = urls.filter { !imageExts.contains($0.pathExtension.lowercased()) }

        if message.type == .user {
            if imageUrls.isEmpty {
                userImageCollectionView.isHidden = true
                userImageHeightConstraint?.update(offset: 0)
            } else {
                userImageCollectionView.isHidden = false
                userImageHeightConstraint?.update(offset: 80)
                userImageDisposeBag = DisposeBag()
                Observable.just(imageUrls)
                    .bind(to: userImageCollectionView.rx.items(cellIdentifier: "RemoteImageCollectionCell", cellType: RemoteImageCollectionCell.self)) { _, url, cell in
                        cell.configure(url: url)
                    }
                    .disposed(by: userImageDisposeBag)
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
            userImageCollectionView.isHidden = true
            userImageHeightConstraint?.update(offset: 0)
            if urls.isEmpty {
                attachmentsStackView.isHidden = true
                messageTopConstraint?.update(offset: 0)
                stackTopConstraint?.update(offset: 0)
            } else {
                attachmentsStackView.isHidden = false
                messageTopConstraint?.update(offset: 8)
                stackTopConstraint?.update(offset: 8)
                attachmentsImageDisposeBag = DisposeBag()
                let attachImageUrls = urls.filter { imageExts.contains($0.pathExtension.lowercased()) }
                let attachFileUrls = urls.filter { !imageExts.contains($0.pathExtension.lowercased()) }
                if attachImageUrls.isEmpty {
                    attachmentsImageCollectionView.isHidden = true
                    attachmentsImageHeightConstraint?.update(offset: 0)
                } else {
                    attachmentsImageCollectionView.isHidden = false
                    Observable.just(attachImageUrls)
                        .bind(to: attachmentsImageCollectionView.rx.items(cellIdentifier: "RemoteImageCollectionCell", cellType: RemoteImageCollectionCell.self)) { _, url, cell in
                            cell.configure(url: url)
                        }
                        .disposed(by: attachmentsImageDisposeBag)
                }
                for url in attachFileUrls {
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
                make.top.equalTo(userImageCollectionView.snp.bottom).offset(8).priority(999)
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
                make.top.equalTo(userImageCollectionView.snp.bottom).offset(8).priority(999)
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
                make.top.equalTo(userImageCollectionView.snp.bottom).offset(8).priority(999)
                make.bottom.equalToSuperview().inset(8).priority(999)
                make.leading.equalToSuperview().inset(16)
                make.trailing.lessThanOrEqualToSuperview().inset(UIScreen.main.bounds.width * 0.2)
            }
        }

        layoutIfNeeded()
        let attachmentHeight = attachmentsStackView.isHidden ? 0 : attachmentsStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + 8
        let imageHeight = userImageCollectionView.isHidden ? 0 : (userImageHeightConstraint?.layoutConstraints.first?.constant ?? 80) + 8
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
            let images = userImageCollectionView.isHidden ? 0 : (userImageHeightConstraint?.layoutConstraints.first?.constant ?? 80) + 8
            let newHeight = messageView.contentSize.height + attach + images
            defer { lastHeight = newHeight }
            return newHeight != lastHeight
        } else {
            let attributed = parser.execute(markdown: text)
            buildStack(from: attributed)
            layoutIfNeeded()
            let attach = attachmentsStackView.isHidden ? 0 : attachmentsStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + 8
            let images = userImageCollectionView.isHidden ? 0 : (userImageHeightConstraint?.layoutConstraints.first?.constant ?? 80) + 8
            let newHeight = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + attach + images
            defer { lastHeight = newHeight }
            return newHeight != lastHeight
        }
    }

}

extension ChatMessageCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == userImageCollectionView {
            return CGSize(width: 80, height: 80)
        }
        let width = collectionView.bounds.width * 0.65
        return CGSize(width: width, height: width)
    }
}
