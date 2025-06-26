# chatGPT
App using OpenAI's ChatGPT API

---

## 🔐 OpenAI API 키 입력 과정 안내

앱을 처음 실행하면 Google 계정으로 로그인한 후, OpenAI API 키를 입력하는 과정을 거칩니다.  

📸 **이미지는 다음 과정을 보여줍니다:**
1. 초기 화면 — Google 로그인 버튼 표시  
2. API 키 입력 화면  
3. OpenAI 키 발급 페이지

API 키는 [OpenAI API Key 페이지](https://platform.openai.com/account/api-keys)에서 발급받을 수 있으며, 입력한 키는 외부 서버에 저장되지 않고 기기 내 Keychain에 안전하게 보관됩니다.

<br>

<p align="center">
  <img src="https://github.com/user-attachments/assets/40659a38-4b44-496b-8455-0a0c202b4345" width="30%">
  <img src="https://github.com/user-attachments/assets/58c8e935-884d-4e97-8e5d-c71b2bea6ab5" width="30%">
  <img src="https://github.com/user-attachments/assets/7dea8a6b-dd15-43f4-a2be-866b3b5b59ee" width="30%">
</p>

---

## 💬 질문하고, 답변을 받아보세요

모델을 선택한 뒤 자유롭게 질문을 입력해보세요.  
입력한 질문에 대해 ChatGPT가 빠르게 응답하며, 대화 형식으로 자연스럽게 이어집니다.

📸 **이미지는 다음을 보여줍니다:**
1. 질문 입력 전 — 사용자가 질문을 입력한 상태  
2. 응답 완료 화면 — 질문에 대한 답변이 출력된 상태  
3. 오류 응답 예시 — API 키 오류 또는 네트워크 실패 시 붉은 말풍선으로 알림

<br>

<p align="center">
  <img src="https://github.com/user-attachments/assets/b7713357-e097-4c5b-9821-a2df8b503cd4" width="30%">
  <img src="https://github.com/user-attachments/assets/c3e7ad53-b649-44c4-b5bb-81218b331a62" width="30%">
  <img src="https://github.com/user-attachments/assets/7dee4b39-f27d-408a-b752-6cc7c4f8e9e5" width="30%">
</p>

---

## 🧠 대화의 흐름을 기억하는 문맥 유지 기능

ChatGPT API는 기본적으로 이전 대화를 기억하지 않기 때문에,  
단순한 요청만으로는 연속된 질문에 자연스럽게 응답하기 어렵습니다.

이 앱은 최근 N개의 메시지를 기억하고,  
대화가 길어질 경우에는 이전 흐름을 간결하게 요약한 system 메시지를 포함하여  
이전 맥락을 바탕으로 질문을 이어갈 수 있도록 구성되어 있습니다.

문맥 유지는 아래와 같이 system 메시지와 최근 대화를 함께 포함시켜  
모델이 이전 맥락을 이해할 수 있도록 구성합니다
이로 인해 **연속적인 주제 흐름**이 자연스럽게 이어집니다.

```swift
//SendChatWithContextUseCase

func execute(prompt: String, model: OpenAIModel, completion: @escaping (Result<String, Error>) -> Void) {
    var messages = [Message]()
    if let summary = contextRepository.summary {
        // 기존 대화 요약 삽입
        messages.append(Message(role: .system, content: summary))  
    }
    // 최근 메시지들 추가
    messages += contextRepository.messages                         
    messages.append(Message(role: .user, content: prompt))

    openAIRepository.sendChat(messages: messages, model: model) { [weak self] result in
        guard let self = self else { return }
        switch result {
        case .success(let reply):
            self.contextRepository.append(role: .user, content: prompt)
            self.contextRepository.append(role: .assistant, content: reply)
            self.contextRepository.trim(to: self.maxHistory)
            completion(.success(reply))
            // 기준 초과 시 요약 생성
            self.summarizeIfNeeded(model: model)                    
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
```

📸 **이미지는 다음을 보여줍니다:**

1. **문맥 유지 기능 미적용 상태** — 이전 질문을 기억하지 못해 어색한 응답이 반환됩니다.  
2. **문맥 유지 기능 적용 상태** — 요약된 대화 흐름을 기반으로 자연스럽게 이어지는 응답이 표시됩니다.

<br>

<p align="center">
  <img src="https://github.com/user-attachments/assets/de61a972-b4bb-4a8c-b5da-2990e532c8cc" width="30%">
  <img src="https://github.com/user-attachments/assets/c7d7a64c-c9c6-46dd-a286-b092b128bebd" width="30%">
</p>


> 이 기능을 통해 긴 대화 속에서도 동일한 주제를 자연스럽게 이어갈 수 있으며,  
> 요약된 system 메시지를 기반으로 마치 ‘기억하는’ 챗봇처럼 응답합니다.

---
## 📂 대화 히스토리 불러오기 및 전환 기능

앱은 Firebase Auth로 로그인한 사용자 기준으로, Firestore에 대화 히스토리를 저장합니다.  
각 대화는 주고받은 내용을 바탕으로 OpenAI API를 활용해 자동으로 제목이 생성되며, 히스토리 목록에서 쉽게 구분할 수 있습니다.
저장된 대화를 선택하면 이전 내용을 불러와 이어서 대화할 수 있습니다.

📸 **이미지는 다음을 보여줍니다:**
1. '성인남자의 단백질 위주 2끼 식단' 대화 내용 화면 — 질문과 답변이 진행된 상태  
2. 히스토리 목록 화면 — '성인남자의 단백질 위주 2끼 식단' 대화가 선택된 상태  
3. '미슐랭 가이드와 타이어 제조사' 대화를 선택한 후, '미슐랭 가이드와 타이어 제조사' 대화 내용이 불러와진 화면

> 로그인한 사용자 기준으로만 히스토리가 저장되며, 자동 생성된 제목 덕분에 원하는 대화를 쉽게 찾고 이어갈 수 있습니다.

<p align="center">
  <img src="https://github.com/user-attachments/assets/10f0195c-8023-4f36-ba71-6e4d09f9ffdc" width="30%">
  <img src="https://github.com/user-attachments/assets/64064bb5-426e-4bc4-bf59-b885ee4d3487" width="30%">
  <img src="https://github.com/user-attachments/assets/99672ca4-c929-4373-a47b-9bf08d43bd07" width="30%">
</p>

---


## 🛠️ 모델 선택 및 유지 기능

입력한 API 키를 기준으로 OpenAI에서 제공하는 모델 목록을 실시간으로 불러옵니다.  
목록에서 원하는 모델을 선택하면 이후 대화에 적용되며, 앱을 종료해도 마지막에 선택한 모델이 자동으로 유지됩니다.

📸 **이미지는 다음을 보여줍니다:**

1. **모델 선택 전 기본 상태** — 최근 사용한 모델이 설정페이지 상단에 표시됩니다.  
2. **모델 선택 화면** — 실시간으로 받아온 사용 가능 모델 리스트가 표시됩니다.  
3. **선택 후 적용된 상태** — 선택한 모델이 상단에 적용된 모습입니다.

> 선택된 모델을 기반으로 OpenAI API 호출이 진행됩니다.

<p align="center">
  <img src="https://github.com/user-attachments/assets/8db7fa03-080c-4842-a5f2-88ce3ec1f78a" width="30%">
  <img src="https://github.com/user-attachments/assets/0ec73b25-50cb-4e2a-8dd2-4ca3d6b54d5a" width="30%">
  <img src="https://github.com/user-attachments/assets/a5d48a9a-ba15-4b44-8471-051ce5d8ca82" width="30%">
</p>

<br>



