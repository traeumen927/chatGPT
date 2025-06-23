//
//  GoogleLoginButton.swift
//  chatGPT
//
//  Created by 홍정연 on 6/19/25.
//

import UIKit
import SnapKit

final class GoogleLoginButton: UIButton {

    // MARK: 구글 아이콘
    private let iconView = UIImageView()

    // MARK: 버튼 이름
    private let buttonLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(hex: "#1F1F1F")
        label.text = "Sign in with Google"
        label.isUserInteractionEnabled = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        self.addSubview(iconView)
        self.addSubview(buttonLabel)

        self.backgroundColor = .white
        self.layer.cornerRadius = 22
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor(hex: "#747775").cgColor
        self.clipsToBounds = true

        iconView.image = UIImage(named: "g-logo")
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false

        self.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        iconView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(20)
        }

        buttonLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }

    // ✅ 버튼 터치 피드백
    override var isHighlighted: Bool {
        didSet {
            self.alpha = isHighlighted ? 0.6 : 1.0
        }
    }
}

