# chatGPT
App using OpenAI's ChatGPT API

---

### 🔐 OpenAI API 키 입력 과정 안내

앱을 처음 실행하면 OpenAI API 키 입력 화면이 표시됩니다.  
키가 없는 사용자는 안내에 따라 OpenAI 공식 플랫폼에서 API 키를 발급받고, 해당 키를 입력 후 저장하면 앱이 정상적으로 동작합니다.

이미지는 다음 과정을 보여줍니다:

1. **API 키 입력 화면** — 키 입력 전 상태  
2. **OpenAI 키 발급 페이지** — 키 생성 위치  
3. **API 키 입력 예시** — 실제 입력 및 저장 동작  

API 키는 [OpenAI API Key 페이지](https://platform.openai.com/account/api-keys)에서 직접 발급받을 수 있으며, 입력한 키는 앱 내에 안전하게 저장됩니다.

<br>

<p align="center">
  <img src="https://github.com/user-attachments/assets/58c8e935-884d-4e97-8e5d-c71b2bea6ab5" width="30%">
  <img src="https://github.com/user-attachments/assets/7dea8a6b-dd15-43f4-a2be-866b3b5b59ee" width="30%">
  <img src="https://github.com/user-attachments/assets/8921f265-2591-4c36-9be3-00dcd1897de8" width="30%">
</p>

---

### 🧠 모델 선택 및 유지 기능

입력한 API 키를 기준으로 OpenAI에서 제공하는 모델 목록을 실시간으로 불러옵니다.  
목록에서 원하는 모델을 선택하면 이후 대화에 적용되며, 앱을 종료해도 마지막에 선택한 모델이 자동으로 유지됩니다.

이미지는 다음 과정을 보여줍니다:

1. **모델 선택 전 기본 상태** — 최근 사용한 모델이 우측 상단에 표시됩니다.  
2. **모델 선택 화면** — 실시간으로 받아온 사용 가능 모델 리스트가 표시됩니다.  
3. **선택 후 적용된 상태** — 선택한 모델이 상단에 적용된 모습입니다.

<br>

<p align="center">
  <img src="https://github.com/user-attachments/assets/2a37b39b-4058-4214-84ff-b74defc5c3f2" width="30%">
  <img src="https://github.com/user-attachments/assets/80317b8e-0b05-4ea0-b4b7-b804c6287bee" width="30%">
  <img src="https://github.com/user-attachments/assets/60efca03-7714-400f-a072-813343678e08" width="30%">
</p>

---

### 💬 질문하고, 답변을 받아보세요

모델을 선택한 뒤에는 자유롭게 질문을 입력할 수 있으며, 선택된 모델이 응답을 반환합니다.  
답변은 말풍선 형식으로 좌우에 구분되어 표시되며, 긴 텍스트도 가독성 좋게 정리되어 출력됩니다.

API 키 오류나 네트워크 문제 등의 요청 실패 시에는, 해당 오류 메시지가 좌측 빨간 말풍선으로 출력되어 상황을 쉽게 인지할 수 있습니다.

이미지는 다음을 보여줍니다:

1. **일반적인 질문/답변 흐름**  
2. **긴 텍스트 응답 처리 예시**  
3. **에러 응답 표시 예시**

<br>

<p align="center">
  <img src="https://github.com/user-attachments/assets/eba4f60c-b4bd-46dc-8ee4-d8bfd9fc3810" width="30%">
  <img src="https://github.com/user-attachments/assets/d7537f77-481f-4a9c-9c25-fead6f287698" width="30%">
  <img src="https://github.com/user-attachments/assets/9b34c511-8806-4891-8def-6cceed50002e" width="30%">
</p>

---

### 🧠 대화의 흐름을 기억하는 문맥 유지 기능

ChatGPT API는 기본적으로 이전 대화를 기억하지 않기 때문에,  
단순한 요청만으로는 연속된 질문에 자연스럽게 응답하기 어렵습니다.

이 앱은 최근 N개의 메시지를 자동으로 유지하고,  
대화가 길어질 경우에는 이전 흐름을 간결하게 요약한 system 메시지를 포함하여  
이전 맥락을 바탕으로 질문을 이어갈 수 있도록 구성되어 있습니다.

문맥 유지는 아래와 같이 system 메시지와 최근 대화를 함께 포함시켜  
모델이 이전 맥락을 이해할 수 있도록 구성합니다:

```swift
// systemMessage: 요약된 메시지 (optional)
// messageHistory: 최근 사용자 대화

let messagesForAPI: [ChatMessage] = {
    var result = [ChatMessage]()
    if let summary = systemMessage {
        result.append(summary) // 🧠 과거 요약 내용을 system 메시지로 삽입
    }
    result.append(contentsOf: messageHistory) // 🔄 최근 대화 메시지들
    return result
}()

openAIService.request(.chat(messages: messagesForAPI, model: selectedModel)) { result in
    ...
}
```

이미지는 다음을 보여줍니다:

1. **문맥 유지 기능 미적용 상태** — 이전 질문을 기억하지 못해 어색한 응답이 반환됩니다.  
2. **문맥 유지 기능 적용 상태** — 요약된 대화 흐름을 기반으로 자연스럽게 이어지는 응답이 표시됩니다.

<br>

<p align="center">
  <img src="https://github.com/user-attachments/assets/f53b2ee0-c8c0-49b6-a90f-3ad6678f7e51" width="30%">
  <img src="https://github.com/user-attachments/assets/c1f46ba6-d476-4e4f-beab-3bfa817db487" width="30%">
</p>


> 이 기능을 통해 긴 대화 속에서도 동일한 주제를 자연스럽게 이어갈 수 있으며,  
> 요약된 system 메시지를 기반으로 마치 ‘기억하는’ 챗봇처럼 응답합니다.
