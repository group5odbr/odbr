# 오디버려 1.0 출시 체크리스트

## Xcode와 실기기

- iPhone 전용 Release archive를 Xcode 26 이상과 iOS 26 SDK로 생성한다.
- 실제 iPhone에서 카메라 허용·거부, 사진 선택, 분석 취소·재시도, 오프라인 검색을 확인한다.
- App Attest가 적용된 배포 빌드에서 Firebase AI 요청이 정상적으로 통과하는지 확인한다.
- 큰 글자, VoiceOver, 다크 모드, 작은 iPhone 화면에서 핵심 버튼과 정정 시트를 확인한다.

## Firebase와 운영

- 개발·스테이징·운영 Firebase 프로젝트와 각 `GoogleService-Info.plist` 배포 절차를 분리한다.
- App Check 요청을 실제 기기에서 관찰한 뒤 운영 enforcement를 활성화한다.
- API 키 제한, 예산 알림, 요청량·오류·지연 모니터링을 설정한다.
- 모델 장애나 중대한 오판 시 AI를 중지할 수 있는 원격 kill switch를 운영 환경에 연결한다.
- 모델명, 프롬프트 버전, 정책 버전 변경과 롤백 절차를 문서화한다.

### Remote Config 운영 파라미터

앱에는 `RemoteConfigDefaults.plist`의 안전한 기본값이 포함되어 있다. 운영 콘솔에는 아래 키를 같은 타입으로 등록하고, 먼저 스테이징 프로젝트에서 검증한다.

| 키 | 타입 | 기본값 | 용도 |
|---|---|---:|---|
| `ai_enabled` | Boolean | `true` | 사진 AI 긴급 중지 |
| `search_ai_enabled` | Boolean | `true` | 검색어 카탈로그 매핑 긴급 중지 |
| `primary_model_version` | String | `gemini-3.1-flash-lite` | 1차 관찰 모델 |
| `review_model_version` | String | `gemini-3.5-flash` | 정밀 관찰 모델 |
| `search_model_version` | String | `gemini-3.1-flash-lite` | 검색 매핑 모델 |
| `analysis_timeout` | Number | `12` | 1차 요청 제한 시간 |
| `review_timeout` | Number | `8` | 정밀 요청 제한 시간 |
| `search_timeout` | Number | `8` | 검색 매핑 제한 시간 |
| `prompt_version` | String | `observation-v1` | 프롬프트 운영 이력 |
| `policy_version` | Number | `2` | 로컬 정책 버전 대조 |
| `minimum_supported_app_version` | String | `1.0.0` | 최소 지원 버전 운영 이력 |

모델명 변경은 스테이징의 고위험 이미지 세트가 통과한 뒤 운영에 반영한다. 긴급 중지는 `ai_enabled=false`로 게시하고 실제 기기에서 검색 대안이 유지되는지 확인한다.

## 개인정보와 App Store Connect

- 실제 Firebase/Google 데이터 보관·로그·학습 사용 조건을 확인한 개인정보처리방침 URL을 준비한다.
- 앱의 사진 전송 동의 문구와 App Store 개인정보 응답이 실제 처리 방식과 일치하는지 대조한다.
- 지원 URL, 문의 이메일, 오픈소스 라이선스 안내를 실제 운영 주소로 확정한다.
- 심사 노트에 사진 전송 목적, 검색 대안, 지역별 안내 우선 원칙, App Check 동작을 설명한다.

## 분리배출 콘텐츠

- `DisposalPolicies.json`의 모든 항목에 출처, 시행일, 검수일이 있는지 CI 결과를 확인한다.
- 고위험 이미지 세트에서 압력용기, 유해 잔류물, 깨진 유리, 손상 배터리의 치명적 오분류가 없는지 실물 평가한다.
- 출시 직전 생활폐기물 분리배출 누리집과 수퍼빈 공식 안내의 변경 사항을 재확인한다.
