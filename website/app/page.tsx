import Image from "next/image";

const APP_STORE_URL = "https://apps.apple.com/kr/";

const steps = [
  {
    number: "01",
    title: "사진을 찍어요",
    description: "버릴 물건 하나를 화면 중앙에 맞춰 촬영해요.",
  },
  {
    number: "02",
    title: "결과를 확인해요",
    description: "어디에 버릴지와 준비할 일을 한눈에 확인해요.",
  },
  {
    number: "03",
    title: "제대로 버려요",
    description: "안내된 순서대로 정리해 간편하게 배출해요.",
  },
];

const features = [
  {
    eyebrow: "PHOTO ANALYSIS",
    title: "사진 한 장으로\n배출 방법을 확인해요",
    description:
      "물건의 모양과 재질, 보이는 분리배출 표시를 Gemini가 함께 살펴보고 알맞은 배출 방법을 안내해요.",
    image: "/app-scan.jpg",
    alt: "오디버려의 사진 촬영 및 분석 시작 화면",
    className: "feature-card feature-card-scan",
  },
  {
    eyebrow: "SMART SEARCH",
    title: "이름으로 검색하고\n준비 순서까지 챙겨요",
    description:
      "영수증, 보조배터리, 깨진 유리처럼 헷갈리는 품목을 검색하면 실제 모양과 배출 전 준비 방법을 차근차근 보여줘요.",
    image: "/app-search.jpg",
    alt: "오디버려의 분리배출 품목 검색 화면",
    className: "feature-card feature-card-search",
  },
  {
    eyebrow: "NEPHRON GUIDE",
    title: "네프론에 넣을 수 있는지\n바로 이어서 확인해요",
    description:
      "투명 음료 페트병과 음료 캔 등 이용 가능한 품목과 준비 방법, 가까운 회수기 찾기까지 한 흐름으로 연결해요.",
    image: "/app-nephron.jpg",
    alt: "오디버려의 네프론 이용 안내 화면",
    className: "feature-card feature-card-nephron",
  },
];

function AppStoreLink({ compact = false }: { compact?: boolean }) {
  return (
    <a
      className={compact ? "store-link store-link-compact" : "store-link"}
      href={APP_STORE_URL}
      aria-label="App Store에서 오디버려 다운로드 페이지 열기"
    >
      <Image
        src="/app-store-badge.svg"
        alt="App Store에서 다운로드하기"
        width={130}
        height={40}
      />
    </a>
  );
}

export default function Home() {
  return (
    <main>
      <nav className="site-nav" aria-label="주요 메뉴">
        <a className="brand" href="#top" aria-label="오디버려 홈">
          <Image src="/app-icon.png" alt="" width={42} height={42} />
          <span>오디버려</span>
        </a>
        <div className="nav-links">
          <a href="#features">주요 기능</a>
          <a href="#how-it-works">사용 방법</a>
          <AppStoreLink compact />
        </div>
      </nav>

      <section className="hero" id="top">
        <div className="hero-copy">
          <p className="eyebrow">사진 분석 · 품목 검색 · 네프론 안내</p>
          <h1>
            버릴 곳이 헷갈릴 때,
            <strong>결과부터 바로 보여드려요.</strong>
          </h1>
          <p className="hero-description">
            사진으로 확인하고, 버리기 전 준비 방법까지.
            <br />
            오디버려와 함께 분리배출을 더 빠르고 간편하게 시작하세요.
          </p>

          <div className="hero-actions">
            <AppStoreLink />
            <span className="release-note">iPhone 앱 · 출시 준비 중</span>
          </div>

          <ul className="value-chips" aria-label="오디버려 핵심 기능">
            <li>Gemini 사진 분석</li>
            <li>배출 준비 순서 안내</li>
            <li>헷갈리는 품목 검색</li>
          </ul>
        </div>

        <div className="hero-stage" aria-label="오디버려 앱 화면 미리보기">
          <div className="hero-glow" />
          <div className="phone phone-search" aria-hidden="true">
            <Image src="/app-search.jpg" alt="" width={368} height={800} sizes="318px" />
          </div>
          <div className="phone phone-result">
            <Image
              src="/app-result.jpg"
              alt="사진 분석 후 배출 방법과 준비 순서를 보여주는 오디버려 화면"
              width={368}
              height={800}
              sizes="330px"
            />
          </div>
        </div>
      </section>

      <section className="steps-section" id="how-it-works" aria-labelledby="steps-title">
        <div className="section-heading centered-heading">
          <p className="eyebrow">HOW IT WORKS</p>
          <h2 id="steps-title">찍고, 확인하고, 제대로 버리기</h2>
        </div>
        <ol className="steps-list">
          {steps.map((step) => (
            <li key={step.number}>
              <span className="step-number">{step.number}</span>
              <div>
                <h3>{step.title}</h3>
                <p>{step.description}</p>
              </div>
            </li>
          ))}
        </ol>
      </section>

      <section className="features-section" id="features" aria-labelledby="features-title">
        <div className="section-heading centered-heading">
          <p className="eyebrow">ONE APP, CLEAR ANSWERS</p>
          <h2 id="features-title">헷갈리는 순간마다 오디버려 하나로</h2>
          <p>
            촬영부터 검색, 배출 준비와 회수기 안내까지 자연스럽게 이어져요.
          </p>
        </div>

        <div className="feature-grid">
          {features.map((feature) => (
            <article className={feature.className} key={feature.eyebrow}>
              <div className="feature-copy">
                <p className="feature-eyebrow">{feature.eyebrow}</p>
                <h3>
                  {feature.title.split("\n").map((line) => (
                    <span key={line}>{line}</span>
                  ))}
                </h3>
                <p>{feature.description}</p>
              </div>
              <div className="feature-phone">
                <Image
                  src={feature.image}
                  alt={feature.alt}
                  width={368}
                  height={800}
                  sizes="(max-width: 720px) 280px, 320px"
                />
              </div>
            </article>
          ))}
        </div>
      </section>

      <section className="result-section" aria-labelledby="result-title">
        <div className="result-copy">
          <p className="eyebrow">FROM RESULT TO ACTION</p>
          <h2 id="result-title">결과만 보여주지 않고, 지금 할 일까지 알려드려요</h2>
          <p>
            배출 장소와 함께 내용물 비우기, 라벨 제거, 다른 재질 분리처럼
            바로 따라 할 수 있는 준비 방법을 한 화면에서 확인하세요.
          </p>
          <ul>
            <li><span>01</span>배출 종류와 확인 결과</li>
            <li><span>02</span>버리기 전 준비 순서</li>
            <li><span>03</span>지역별 안내 확인 포인트</li>
          </ul>
        </div>
        <div className="result-phone-wrap">
          <div className="result-orbit result-orbit-one" />
          <div className="result-orbit result-orbit-two" />
          <div className="phone result-phone">
            <Image
              src="/app-result.jpg"
              alt="플라스틱 용기와 트레이의 배출 준비 방법을 보여주는 오디버려 분석 결과"
              width={368}
              height={800}
              sizes="360px"
            />
          </div>
        </div>
      </section>

      <section className="download-section" id="app-store" aria-labelledby="download-title">
        <Image
          className="download-icon"
          src="/app-icon.png"
          alt="오디버려 앱 아이콘"
          width={1254}
          height={1254}
          sizes="92px"
        />
        <p className="eyebrow">COMING SOON ON THE APP STORE</p>
        <h2 id="download-title">오늘 버릴 물건, 이제 오디버려에 물어보세요</h2>
        <p>사진 한 장으로 더 간편한 분리배출을 시작하세요.</p>
        <AppStoreLink />
      </section>

      <footer>
        <a className="brand footer-brand" href="#top">
          <Image src="/app-icon.png" alt="" width={34} height={34} />
          <span>오디버려</span>
        </a>
        <p>사진 한 장으로 확인하는 분리배출 도우미</p>
        <span>© 2026 오디버려</span>
      </footer>
    </main>
  );
}
