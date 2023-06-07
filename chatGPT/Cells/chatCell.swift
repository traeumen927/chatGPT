//
//  chatCell.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/05.
//

import UIKit
import SnapKit

class chatCell: UITableViewCell {
    
    static let cellId = "chatCell"
    
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
    
    private func layout() {
        self.addSubview(contentLabel)
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(18)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
    
    func bind(content:String) {
        self.contentLabel.text = content
    }
}
