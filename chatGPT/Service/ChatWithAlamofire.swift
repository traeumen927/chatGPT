//
//  ChatWithAlamofire.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/13.
//

import Alamofire

class ChatWithAlamofire {
    private let url = "https://api.openai.com/v1/chat/completions"
    private let header: HTTPHeaders = [
        "Content-Type":"application/json",
        "Authorization":"Bearer \(APIKey.openAI)"
    ]
    
    func request(text:String) -> DataRequest {
        
        let body = OpenAICompletionBody(model: Setting.shared.model, messages: [Message(role: .user, content: text)], temperature: 0.7, stream: false)
        
        return AF.request(url, method: .post, parameters: body, encoder: .json, headers: header)
    }
    
    func requestStream(text:String) -> DataStreamRequest {
        let body = OpenAICompletionBody(model: Setting.shared.model, messages: [Message(role: .user, content: text)], temperature: 0.7, stream: true)
        
        return AF.streamRequest(url, method: .post, parameters: body, encoder: .json, headers: header)
    }
    
    func parse(data:String) -> [StreamChat] {
        let response = data.split(separator: "data:").map({$0.trimmingCharacters(in: .whitespacesAndNewlines)}).filter({!$0.isEmpty})
        
        return response.compactMap { json in
            guard let data = json.data(using: .utf8),
                  let stream = try? JSONDecoder().decode(StreamChat.self, from: data) else {
                return nil
            }
            return stream
        }
    }

}


