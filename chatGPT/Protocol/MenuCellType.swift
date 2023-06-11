//
//  MenuCellType.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/09.
//

import UIKit

protocol MenuCellType where Self: UITableViewCell {
    var menuIcon: UIImageView { get set }
    var titleLabel: UILabel { get set }
    var component: UIView { get set }
}
