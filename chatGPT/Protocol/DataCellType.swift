//
//  DataCellType.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/07.
//

import Foundation

protocol DataCellType {
    func layout()
    func bind<T:Codable>(data: T)
}
