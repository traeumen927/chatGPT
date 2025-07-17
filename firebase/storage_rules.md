# Firebase Storage 보안 규칙 예시

Firebase 콘솔에서 **Storage** 메뉴의 **규칙** 탭에 아래 내용을 설정하세요.

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /attachments/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
