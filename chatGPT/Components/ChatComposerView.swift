//
//  ChatComposerView.swift
//  chatGPT
//
//  Created by 홍정연 on 6/13/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxRelay

final class ChatComposerView: UIView, UITextViewDelegate {
    
    private let disposeBag = DisposeBag()
    
    // MARK: - UI
    // MARK: 채팅 텍스트뷰
    private let textView = UITextView()
    
    // MARK: 플레이스 홀더 라벨
    private let placeholderLabel = UILabel()
    
    // MARK: 전송 버튼
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.up.circle"), for: .normal)
        button.tintColor = ThemeColor.tintDark
        return button
    }()

    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = ThemeColor.tintDark
        return button
    }()

    private let imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        return view
    }()

    private var collectionViewHeightConstraint: Constraint?

    let attachments = BehaviorRelay<[Attachment]>(value: [])
    
    // MARK: - Output
    
    // MARK: 외부 전달용 클로져
    var onSendButtonTapped: ((String, [Attachment]) -> Void)?
    var onStopButtonTapped: (() -> Void)?
    var onPlusButtonTapped: (() -> Void)?

    var plusButtonMenu: UIMenu? {
        get { plusButton.menu }
        set {
            plusButton.menu = newValue
            plusButton.showsMenuAsPrimaryAction = newValue != nil
        }
    }

    var plusButtonEnabled: Bool = false {
        didSet {
            plusButton.isEnabled = plusButtonEnabled
            plusButton.tintColor = plusButtonEnabled ? ThemeColor.tintDark : .gray
        }
    }

    var isSending: Bool = false {
        didSet {
            let name = isSending ? "pause.circle" : "arrow.up.circle"
            sendButton.setImage(UIImage(systemName: name), for: .normal)
        }
    }
    
    // MARK: - Constraints
    private var textViewHeightConstraint: Constraint?
    
    // MARK: - Configurable Constants
    private var lineHeight: CGFloat {
        return textView.font?.lineHeight ?? UIFont.systemFont(ofSize: 14).lineHeight
    }
    
    private var minTextViewHeight: CGFloat {
        let insets = textView.textContainerInset.top + textView.textContainerInset.bottom
        return lineHeight + insets
    }
    
    private var maxTextViewHeight: CGFloat {
        return minTextViewHeight * 5
    }
    
    // MARK: - External Bindable Properties
    var text: String {
        get { textView.text }
        set {
            textView.text = newValue
            updatePlaceholderVisibility()
            adjustTextViewHeight()
        }
    }
    
    // MARK: 폰트
    var font: UIFont = .systemFont(ofSize: 14) {
        didSet {
            textView.font = font
            placeholderLabel.font = font
        }
    }
    
    // MARK: 텍스트컬러
    var textColor: UIColor = .label {
        didSet { textView.textColor = textColor }
    }
    
    // MARK: 플레이스홀더
    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            updatePlaceholderVisibility()
        }
    }
    
    // MARK: 플레이스홀더 컬러
    var placeholderColor: UIColor = .secondaryLabel {
        didSet { placeholderLabel.textColor = placeholderColor }
    }
    
    // MARK: 부모뷰 배경색
    var composerColor: UIColor = .systemBackground {
        didSet { backgroundColor = composerColor }
    }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layout()
        self.bind()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.layout()
        self.bind()
    }
    
    // MARK: - 레이아웃 설정
    private func layout() {
        
        // MARK: 상단 좌우 radius
        self.layer.cornerRadius = 25
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // MARK: 채팅과 관련된 컴포넌트가 담길 뷰
        let toolBoxView = UIView()
        [self.imageCollectionView, self.textView, self.placeholderLabel, toolBoxView].forEach(addSubview(_:))
        [self.plusButton, self.sendButton].forEach(toolBoxView.addSubview(_:))
        
        // MARK: TextVeiw 설정
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.font = font
        textView.textColor = textColor
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.textContainer.lineFragmentPadding = 0
        
        // MARK: PlaceHolder 설정
        placeholderLabel.font = font
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.numberOfLines = 1
        placeholderLabel.text = placeholder
        
        imageCollectionView.register(ChatComposerImageCell.self, forCellWithReuseIdentifier: "ChatComposerImageCell")

        imageCollectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            self.collectionViewHeightConstraint = make.height.equalTo(0).constraint
        }

        textView.snp.makeConstraints { make in
            make.top.equalTo(imageCollectionView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            self.textViewHeightConstraint = make.height.equalTo(minTextViewHeight).constraint
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.leading.equalTo(textView).offset(8)
            make.top.equalTo(textView).offset(8)
        }
        
        toolBoxView.snp.makeConstraints { make in
            make.top.equalTo(self.textView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide)
        }

        self.sendButton.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.width.height.equalTo(44)
        }
        self.plusButton.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.height.equalTo(44)
        }
    }
    
    // MARK: - Bind
    private func bind() {
        self.textView.rx.text.orEmpty
            .distinctUntilChanged()
            .filter { !$0.isEmpty }
            .subscribe(onNext: { [weak self] _ in
                self?.updatePlaceholderVisibility()
                self?.adjustTextViewHeight()
            })
            .disposed(by: disposeBag)
        
        self.sendButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                if self.isSending {
                    self.onStopButtonTapped?()
                } else {
                    let text = self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    self.onSendButtonTapped?(text, self.attachments.value)
                    self.textView.text = ""
                    self.attachments.accept([])
                    self.updatePlaceholderVisibility()
                    self.adjustTextViewHeight()
                }
            })
            .disposed(by: disposeBag)

        self.plusButton.rx.tap
            .bind { [weak self] in
                guard let self else { return }
                if self.plusButton.menu == nil {
                    self.onPlusButtonTapped?()
                }
            }
            .disposed(by: disposeBag)

        attachments
            .bind(to: imageCollectionView.rx.items(cellIdentifier: "ChatComposerImageCell", cellType: ChatComposerImageCell.self)) { [weak self] index, item, cell in
                cell.configure(attachment: item) { [weak self] in
                    self?.removeAttachment(at: index)
                }
            }
            .disposed(by: disposeBag)

        imageCollectionView.rx.observe(CGSize.self, "contentSize")
            .compactMap { $0 }
            .distinctUntilChanged { $0 == $1 }
            .observe(on: MainScheduler.instance)
            .bind { [weak self] size in
                self?.collectionViewHeightConstraint?.update(offset: size.height)
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Dynamic Resize
    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !(textView.text?.isEmpty ?? true)
    }
    
    private func adjustTextViewHeight() {
        guard textView.bounds.width > 0 else { return }
        
        let fittingSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        let size = textView.sizeThatFits(fittingSize)
        
        let targetHeight = min(max(size.height, minTextViewHeight), maxTextViewHeight)
        textView.isScrollEnabled = size.height > maxTextViewHeight
        textViewHeightConstraint?.update(offset: targetHeight)
        layoutIfNeeded()
    }
    
    // MARK: - UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        adjustTextViewHeight()
    }

    private func removeAttachment(at index: Int) {
        var items = attachments.value
        guard index < items.count else { return }
        items.remove(at: index)
        attachments.accept(items)
    }
}
