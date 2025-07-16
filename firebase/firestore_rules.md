# Firestore 보안 규칙 예시

Firebase 콘솔에서 **Firestore Database** 메뉴의 **규칙** 탭에 아래 내용을 설정하세요.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // preferences 컬렉션
    match /preferences/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // conversations 컬렉션
    match /conversations/{userId}/items/{conversationId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // models 컬렉션
    match /models/{modelId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```
