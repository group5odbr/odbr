# Firebase AI 구성 및 공개 리포 정책

ODBR은 Firebase AI Logic을 iOS 클라이언트에서 사용합니다. 이 문서는 공개
GitHub 리포지토리에서도 앱 설정을 일관되게 유지하기 위한 기준입니다.

## 버전 관리 정책

- `odbr/GoogleService-Info.plist`는 의도적으로 커밋합니다. Firebase iOS
  클라이언트 설정 파일이며, 앱 번들에 포함되는 값입니다.
- iOS 앱의 `.env` 또는 `.xcconfig`에 API 키를 옮겨도 앱 바이너리에서 확인할
  수 있으므로 비밀값 보호 수단으로 사용하지 않습니다.
- 현재 Xcode 프로젝트는 `odbr` 디렉터리를 동기화하므로, 해당 plist는 별도의
  `project.pbxproj` 편집 없이 앱 리소스에 포함됩니다.
- 포크하거나 별도 Firebase 프로젝트를 사용할 경우에는 자신의 Firebase iOS 앱에
  맞는 `GoogleService-Info.plist`로 교체합니다.

## 절대 커밋하지 않는 값

- Firebase 또는 Google Cloud 서비스 계정 JSON
- App Check Debug 토큰
- 서버 API 키, OAuth client secret, 액세스 토큰 및 개인키
- 인증서 또는 서명용 `.pem`, `.p12`, `.p8` 파일

이런 값이 필요한 기능은 iOS 앱에 넣지 않고, 서버 또는 Secret Manager에서만
사용합니다.

## Firebase Console 확인 항목

공개 배포 전 Firebase/Google Cloud Console에서 다음을 확인합니다.

1. Firebase API 키는 Firebase 관련 API에만 사용되도록 API 제한과 쿼터를
   검토합니다.
2. Firebase AI Logic의 App Check 요청을 실제 기기에서 먼저 관찰합니다.
3. Release/TestFlight 빌드가 App Attest를 통해 정상 요청되는 것을 확인한 뒤
   App Check enforcement를 활성화합니다.
4. Debug App Check 토큰은 개발 기기에만 등록하고, 노출되면 즉시 폐기합니다.

`odbrApp`은 Debug에서만 `AppCheckDebugProviderFactory`를 사용하며, Release에서는
`AppAttestProvider`를 사용합니다.

## 점검 명령

```sh
plutil -lint odbr/GoogleService-Info.plist
git diff --check
git status --short
```

공개 push 전에는 GitHub의 Secret Scanning 및 Push Protection도 활성화합니다.
