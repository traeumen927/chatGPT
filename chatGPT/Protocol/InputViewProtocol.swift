//
//  InputViewProtocol.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/05.
//

import Foundation

protocol InputViewProtocol {
    func beginEditing()
    func endEditing()
    func enterPressed(chat:String)
}
