# 오디버려 랜딩페이지

오디버려 iOS 앱을 소개하는 Next.js 랜딩페이지입니다.

## 로컬 실행

```bash
npm install
npm run dev
```

## Vercel 배포

1. 이 저장소를 GitHub에 푸시합니다.
2. Vercel에서 **Add New → Project**를 선택합니다.
3. 저장소를 불러온 뒤 **Root Directory**를 `website`로 지정합니다.
4. Framework Preset이 **Next.js**인지 확인하고 Deploy를 실행합니다.

별도의 빌드 명령어나 출력 디렉토리는 지정하지 않아도 됩니다.

커스텀 도메인을 연결한 뒤에는 Vercel 환경변수 `NEXT_PUBLIC_SITE_URL`에
`https://example.com` 형식의 실제 주소를 설정하면 공유 이미지 주소에도 반영됩니다.
