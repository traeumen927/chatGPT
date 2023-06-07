//
//  ChatViewModel.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/05.
//

import Foundation
import RxSwift
import RxGesture
import RxCocoa
import Alamofire

class ChatViewModel {
    
    var dispostBag = DisposeBag()
    
    let questionSubject: PublishSubject<String> = PublishSubject<String>()
    let messageSubject: PublishSubject<Message> = PublishSubject<Message>()
    let loadingSubject: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    
    
    func askQuestion(question:String) {
        self.messageSubject.onNext(Message(role: .user, content: question))
        self.loadingSubject.onNext(true)
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {return}
        
        let header: HTTPHeaders = [
            "Content-Type":"application/json",
            "Authorization":"Bearer \(APIKey.openAI)"
        ]
                
        let body = OpenAICompletionBody(model: "gpt-3.5-turbo", messages: [Message(role: .user, content: question)], temperature: 0.7)
        
        AF.request(url, method: .post, parameters: body, encoder: .json, headers: header).responseDecodable(of: Chat.self) { response in
            switch response.result {
            case .success(let data):
                
                data.choices.forEach { choice in
                    self.messageSubject.onNext(choice.message)
                }
                self.loadingSubject.onNext(false)
                
            case .failure(let error):
                print(error.localizedDescription)
                self.loadingSubject.onNext(false)
            }
        }
    }
}
