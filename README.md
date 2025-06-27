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
3. 추가 요청 화면 - 1차로 전달 받은 답변을 토대로 2차 답변이 출력된 상태  
4. 오류 응답 예시 — API 키 오류 또는 네트워크 실패 시 붉은 말풍선으로 알림

<br>

<p align="center">
  <img src="https://github.com/user-attachments/assets/424b58ad-2b14-4061-8a5d-3e51e0357c8f" width="24%">
  <img src="https://github.com/user-attachments/assets/149add30-3b5a-4d0c-b400-06e7620d7bd7" width="24%">
  <img src="https://github.com/user-attachments/assets/d2efe748-d5eb-42a1-b416-19f5fa8edba8" width="24%">
  <img src="https://github.com/user-attachments/assets/4d376015-08bd-4061-84f4-428e31f91a52" width="24%">
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
  <img src="https://github.com/user-attachments/assets/18f041a2-094f-4777-8607-b172687db73e" width="30%">
  <img src="https://github.com/user-attachments/assets/fde1240b-12ac-4e07-9a95-6d3a30d0d07c" width="30%">
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
3. 목록에서 '한국 소설 추천: 살인자의 기억법' 대화를 선택하자, '한국 소설 추천: 살인자의 기억법' 대화 내용이 불러와진 화면

> 로그인한 사용자 기준으로만 히스토리가 저장되며, 자동 생성된 제목 덕분에 원하는 대화를 쉽게 찾고 이어갈 수 있습니다.

<p align="center">
  <img src="https://github.com/user-attachments/assets/b6941407-09c4-4d68-9dd3-c14dc347dd2c" width="30%">
  <img src="https://github.com/user-attachments/assets/acb180a5-a0d6-45d2-a6ee-c8de3fec47d4" width="30%">
  <img src="https://github.com/user-attachments/assets/8da5214e-2254-457c-9195-063dd362bcb9" width="30%">
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
  <img src="https://github.com/user-attachments/assets/2b779758-cc9e-498d-b126-f9c2db502c8b" width="30%">
  <img src="https://github.com/user-attachments/assets/58bb6f8b-9e15-4954-a2fd-3b3e78f076b1" width="30%">
  <img src="https://github.com/user-attachments/assets/e0ba6e38-6b79-41ba-a357-4498463388cd" width="30%">
</p>

<br>

---

## 🔁 스트리밍 응답 지원 (Stream On/Off)
OpenAI의 Chat Completions API는 응답을 스트리밍 방식으로 전달받는 기능을 지원합니다.
이 앱에서는 스트리밍 On/Off를 선택적으로 사용할 수 있도록 구성되어 있으며,
스트리밍 활성화 시 더 빠르게 응답의 일부를 사용자에게 보여줄 수 있습니다.

```swift
openAIService.request(.chat(prompt: text, model: model, stream: true)) { ... }
```

📸 **아래 이미지는 스트림 모드 ON일 때 답변을 시각적으로 보여줍니다.**

<p align="center">
  <img src="https://github.com/user-attachments/assets/b8f23d59-7323-447e-a54d-1a927f9af58e" width="30%">
  <img src="https://github.com/user-attachments/assets/748c8daa-4561-4291-8a11-ee0319a1a70b" width="30%">
  <img src="https://github.com/user-attachments/assets/ba97e8be-ceff-467b-8435-531b25c600bd" width="30%">
</p>

>설정 화면에서 스트림 기능을 끄고 켤 수 있습니다.

<br>

---

## 🌗 시스템 테마 대응 (다크모드 & 라이트모드)
이 앱은 iOS의 시스템 인터페이스 스타일(라이트/다크 모드) 를 자동으로 감지하여,
사용자 환경에 맞는 UI가 자연스럽게 적용되도록 구성되어 있습니다.

UIKit 기반 구성 요소 및 커스텀 UI 모두 traitCollection에 따라 적절한 색상을 반영하며,
ThemeColor를 통해 일관된 색상 시스템을 관리하고 있습니다.

📸 **아래 이미지는 라이트 모드와 다크 모드에서의 UI 예시입니다**


<p align="center">
  <img src="https://github.com/user-attachments/assets/57b8a0c5-a065-4d4e-8e3c-da94c17012f8" width="30%">
  <img src="https://github.com/user-attachments/assets/2eb1f934-b37a-47c2-9e6c-a90b053eb59c" width="30%">
  <img src="https://github.com/user-attachments/assets/3fe7d06c-f4e8-4b44-be27-4bf05d3db109" width="30%">
</p>
<p align="center">
  <img src="https://github.com/user-attachments/assets/948a03f8-928a-4cea-8db8-e23954384340" width="30%">
  <img src="https://github.com/user-attachments/assets/a791940e-9331-4ae4-bc31-204f9963705a" width="30%">
  <img src="https://github.com/user-attachments/assets/0981c436-6556-4944-8ac0-ff3db9dbff09" width="30%">
</p>

>개발 환경에서는 시뮬레이터나 디바이스에서 테마 변경을 통해 시각적으로 쉽게 테스트할 수 있습니다.
>별도 설정 없이 시스템 설정을 그대로 따르며, 필요한 경우 수동 제어도 고려할 수 있도록 구조를 단순하게 유지했습니다.




