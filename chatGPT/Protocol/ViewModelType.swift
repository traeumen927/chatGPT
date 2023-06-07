//
//  ViewModelType.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/05.
//

import RxSwift

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    var dispostBag: DisposeBag {get set}
}
