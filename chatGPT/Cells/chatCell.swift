//
//  chatCell.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/05.
//

import UIKit
import SnapKit

class chatCell: UITableViewCell, DataCellType {
    
    
    static let cellId = "chatCell"
    
    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let contentLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layout() {
        self.addSubview(bubbleView)
        bubbleView.addSubview(contentLabel)
        
        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.trailing.equalToSuperview().offset(-18)
            make.leading.equalToSuperview().offset(18)
        }
        
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-8)
            make.width.lessThanOrEqualTo(self.bounds.size.width * 0.8)
        }
    }
    
    
    func bind<T>(data: T) where T : Decodable, T : Encodable {
        guard let message = data as? Bubble else {return}
        
        switch message.role {
            
        case .user:
            self.bubbleView.backgroundColor = .systemBlue
            self.contentLabel.textColor = .white
        case .assistant:
            self.bubbleView.backgroundColor = .systemGray6
            self.contentLabel.textColor = .black
        case .error:
            self.bubbleView.backgroundColor = .systemPink
            self.contentLabel.textColor = .white
        }
        
        self.contentLabel.text = message.content
        
        bubbleView.snp.remakeConstraints({ make in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            if message.role == .user {
                make.trailing.equalToSuperview().offset(-18)
            } else {
                make.leading.equalToSuperview().offset(18)
            }
        })
    }
}
