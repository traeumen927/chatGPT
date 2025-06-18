//
//  OpenAIError.swift
//  chatGPT
//
//  Created by 홍정연 on 6/16/25.
//

import Foundation

enum OpenAIError: Error {
    /// API 키가 설정되어 있지 않거나, Keychain에서 가져오지 못했을 때 발생
    case missingAPIKey
    
    /// body 파라미터가 JSON 형식으로 인코딩되지 않았거나 Encodable 실패 시 발생
    case invalidRequestBody
    
    /// URL 생성이 실패했을 때 발생 (baseURL + path 조합 문제 등)
    case invalidURL
    
    /// 응답 데이터가 nil일 때 발생 (서버에서 아무 응답이 오지 않았거나 empty response)
    case noData
    
    /// 404 Not Found — 요청한 모델이 존재하지 않거나, 현재 API 키로 접근 권한이 없을 때
    case modelNotFound
    
    /// 429 Too Many Requests — 너무 짧은 시간에 요청을 과도하게 보낸 경우 (rate limit 초과)
    case rateLimitExceeded
    
    /// 500~599번대 서버 에러 또는 기타 예상치 못한 HTTP 상태 코드가 반환되었을 때
    case serverError(statusCode: Int)
    
    /// 응답은 왔지만 JSON 디코딩에 실패했을 때 (응답 형식이 예상과 다를 경우)
    case decodingError
}

extension OpenAIError {
    var errorMessage: String {
        switch self {
        case .missingAPIKey: return "API 키가 설정되지 않았습니다."
        case .invalidRequestBody: return "요청 본문 형식이 잘못되었습니다."
        case .invalidURL: return "URL이 잘못되었습니다."
        case .noData: return "서버에서 데이터를 받지 못했습니다."
        case .modelNotFound: return "요청한 모델을 찾을 수 없습니다."
        case .rateLimitExceeded: return "요청이 너무 많습니다. 잠시 후 다시 시도해주세요."
        case .serverError(let code): return "서버 에러가 발생했습니다. (코드: \(code))"
        case .decodingError: return "응답 해석에 실패했습니다."
        }
    }
}
