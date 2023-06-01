//
//  ViewController.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/01.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        questionToChatGPT(question: "how are you?")
    }
    
    func questionToChatGPT(question:String) {
        
        let param:[String:Any] = [
            "model":"gpt-3.5-turbo",
            "messages": [
                "role":"user",
                "content":question
            ],
            "temperature":0.7
        ]
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions"),
              let body = try? JSONSerialization.data(withJSONObject: param) else {return}
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.addValue("Content-Type", forHTTPHeaderField: "application/json")
        request.addValue("Authorization", forHTTPHeaderField: "Bearer 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")
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let error = error {
                print("error: \(error)")
            }
            
            guard let data = data,
                  let result = String(data: data, encoding: .utf8) else {return}
            print(result)
        }
        
        task.resume()
        
        
        //request.addValue("Authorization", forHTTPHeaderField: "여기에 openAI API KEY를 입력해주세요.")
        
    }
}

/*
 curl https://api.openai.com/v1/chat/completions \
   -H "Content-Type: application/json" \
   -H "Authorization: Bearer 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" \
   -d '{
      "model": "gpt-3.5-turbo",
      "messages": [{"role": "user", "content": "How are you?"}],
      "temperature": 0.7
    }'
 */
