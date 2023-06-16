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
    let bubbleRelay: BehaviorRelay<[Bubble]> = BehaviorRelay(value: [Bubble]())
    let loadingSubject: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    let completeSubject: PublishSubject<Void> = PublishSubject<Void>()
    
    
    func chatEntered(chat: String) {
        self.bubbleRelay.accept(bubbleRelay.value + [Bubble(id: UUID().uuidString, role: .user, content: chat)])
        self.completeSubject.onNext(())
        Setting.shared.stream ? loadChatStream(chat: chat) : loadChat(chat: chat)
    }
    
    
    // MARK: Stream Mode On
    private func loadChatStream(chat:String) {
        let service = ChatWithAlamofire()
        
        service.requestStream(text: chat).responseStreamString { stream in
            switch stream.event {
                
            case .stream(let result):
                switch result {
                    
                case .success(let data):
                    
                    let stream = service.parse(data: data)
                    
                    stream.forEach { chunk in
                        
                        guard let choice = chunk.choices.first,
                              let newContent = choice.delta.content else {return}
                        
                        if let streamIndex = self.bubbleRelay.value.lastIndex(where: {$0.id == chunk.id}) {
                            // MARK: 기존에 동일한 id를 가진 미완성 Stream 데이터가 존재함 -> 스트림 정보 업데이트
                            var bubbles = self.bubbleRelay.value
                            let content = bubbles[streamIndex].content + newContent
                            bubbles[streamIndex] = Bubble(id: chunk.id, role: .assistant, content: content)
                            self.bubbleRelay.accept(bubbles)
                        } else {
                            // MARK: 기존에 동일한 id를 가진 미완성 Stream 데이터가 존재하지 않음 -> 신규생성
                            let newBubble = Bubble(id: chunk.id, role: .assistant, content: newContent)
                            self.bubbleRelay.accept(self.bubbleRelay.value + [newBubble])
                        }
                    }
                }
                
                
                
            case .complete(let data):
                print(data)
                self.completeSubject.onNext(())
                break
            }
        }
    }
    
    // MARK: Stream Mode Off
    private func loadChat(chat:String) {
        
        self.loadingSubject.onNext(true)
        
        let service = ChatWithAlamofire()
        
        service.request(text: chat).responseDecodable(of: Chat.self) { response in
            switch response.result {
                
            case .success(let data):
                
                guard let choice = data.choices.first else {return}
                self.bubbleRelay.accept(self.bubbleRelay.value + [Bubble(id: data.id, role: choice.message.role, content: choice.message.content)])
                self.loadingSubject.onNext(false)
                self.completeSubject.onNext(())
                
            case .failure(let error):
                print(error.localizedDescription)
                self.loadingSubject.onNext(false)
            }
        }
    }
}
