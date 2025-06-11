# chatGPT Clean Architecture Base

이 저장소는 ChatGPT API를 사용한 앱 개발을 위한 클린 아키텍처 기반 구조를 제공합니다.

## 폴더 구조
- `App` : 앱 실행과 관련된 파일 (AppDelegate, SceneDelegate 등)
- `Domain` : 엔티티와 UseCase 정의
- `Data` : 리포지토리 구현 등 데이터 계층
- `Presentation` : ViewController와 ViewModel 등 UI 계층

각 레이어는 독립적으로 관리되며, 필요에 따라 의존성을 주입하여 사용합니다.
