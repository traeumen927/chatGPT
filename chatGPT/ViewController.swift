//
//  ViewController.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/01.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        questionToChatGPT(question: "iOS 개발자의 미래는 어떻게 될까?")
    }
    
    func questionToChatGPT(question:String) {
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {return}
        
        let header: HTTPHeaders = [
            "Content-Type":"application/json",
            "Authorization":"Bearer \(APIKey.openAI)"
        ]
                
        let body = OpenAICompletionBody(model: "gpt-3.5-turbo", messages: [Message(role: "user", content: question)], temperature: 0.7)
        
        AF.request(url, method: .post, parameters: body, encoder: .json, headers: header).responseDecodable(of: Chat.self) { response in
            switch response.result {
            case .success(let data):
                print("질문: \(question)")
                print("답변: \(data.choices[0].message.content)")
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
