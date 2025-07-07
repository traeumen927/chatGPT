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

    // 대화 데이터 (사용자 UID를 최상위 컬렉션 이름으로 사용)
    match /{userId}/{conversationId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
