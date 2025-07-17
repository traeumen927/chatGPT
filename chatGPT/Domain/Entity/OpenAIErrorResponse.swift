import Foundation

struct OpenAIErrorResponse: Decodable {
    struct OpenAIErrorDetail: Decodable {
        let message: String
        let type: String?
        let param: String?
        let code: String?
    }
    let error: OpenAIErrorDetail
}
