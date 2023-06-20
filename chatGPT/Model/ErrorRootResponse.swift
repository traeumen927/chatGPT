//
//  ErrorRootResponse.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/20.
//

import Foundation

struct ErrorRootResponse: Decodable {
    let error: ErrorResponse
}


struct ErrorResponse: Decodable {
    let message: String
    let type: String?
}
