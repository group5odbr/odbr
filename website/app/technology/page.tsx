import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import styles from "./technology.module.css";

export const metadata: Metadata = {
  title: "오디버려 AI 기술 — 스캔과 검색 분석 로직",
  description:
    "오디버려의 스캔 AI와 검색 AI가 사진과 검색어를 해석하고, 검수된 규칙과 카탈로그로 배출 안내를 완성하는 과정을 소개합니다.",
};

type IconName =
  | "camera"
  | "search"
  | "scan"
  | "sparkles"
  | "braces"
  | "shield"
  | "database"
  | "check"
  | "route"
  | "sliders"
  | "question";

const safeguards: Array<{
  icon: IconName;
  title: string;
  description: string;
}> = [
  {
    icon: "braces",
    title: "구조화된 응답",
    description:
      "Gemini의 출력을 정해진 JSON 스키마로 제한해 자유 서술이 판정에 섞이지 않게 합니다.",
  },
  {
    icon: "shield",
    title: "신뢰도·충돌 검증",
    description:
      "촬영 상태와 근거별 기준, OCR과 사진 관찰의 충돌을 앱에서 다시 확인합니다.",
  },
  {
    icon: "database",
    title: "검수된 규칙과 카탈로그",
    description:
      "배출 경로와 준비 방법은 앱에 포함된 정책과 상품 카탈로그에서 가져옵니다.",
  },
  {
    icon: "question",
    title: "근거 부족 시 판단 보류",
    description:
      "형태나 재질이 불분명하면 억지로 분류하지 않고 다시 촬영하거나 검색하도록 안내합니다.",
  },
];

const stack = [
  "SwiftUI",
  "Vision OCR",
  "Firebase AI Logic",
  "Gemini",
  "Remote Config",
  "App Check",
];

function TechIcon({ name }: { name: IconName }) {
  const common = {
    fill: "none",
    stroke: "currentColor",
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
    strokeWidth: 1.8,
  };

  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      {name === "camera" && (
        <>
          <path {...common} d="M4 8.5h3l1.4-2h7.2l1.4 2h3v9H4z" />
          <circle {...common} cx="12" cy="13" r="3.2" />
        </>
      )}
      {name === "search" && (
        <>
          <circle {...common} cx="10.5" cy="10.5" r="5.5" />
          <path {...common} d="m15 15 4 4" />
        </>
      )}
      {name === "scan" && (
        <>
          <path {...common} d="M8 4H5a1 1 0 0 0-1 1v3M16 4h3a1 1 0 0 1 1 1v3M8 20H5a1 1 0 0 1-1-1v-3M16 20h3a1 1 0 0 0 1-1v-3" />
          <path {...common} d="M8 12h8" />
        </>
      )}
      {name === "sparkles" && (
        <>
          <path {...common} d="M12 3c.5 3.1 1.9 4.5 5 5-3.1.5-4.5 1.9-5 5-.5-3.1-1.9-4.5-5-5 3.1-.5 4.5-1.9 5-5Z" />
          <path {...common} d="M18 14c.3 1.8 1.2 2.7 3 3-1.8.3-2.7 1.2-3 3-.3-1.8-1.2-2.7-3-3 1.8-.3 2.7-1.2 3-3Z" />
        </>
      )}
      {name === "braces" && (
        <>
          <path {...common} d="M9 4H7.5A1.5 1.5 0 0 0 6 5.5v4A1.5 1.5 0 0 1 4.5 11 1.5 1.5 0 0 1 6 12.5v4A1.5 1.5 0 0 0 7.5 18H9M15 4h1.5A1.5 1.5 0 0 1 18 5.5v4a1.5 1.5 0 0 0 1.5 1.5 1.5 1.5 0 0 0-1.5 1.5v4a1.5 1.5 0 0 1-1.5 1.5H15" />
        </>
      )}
      {name === "shield" && (
        <>
          <path {...common} d="M12 3 19 6v5c0 4.2-2.8 7.7-7 10-4.2-2.3-7-5.8-7-10V6z" />
          <path {...common} d="m9 12 2 2 4-4" />
        </>
      )}
      {name === "database" && (
        <>
          <ellipse {...common} cx="12" cy="6" rx="7" ry="3" />
          <path {...common} d="M5 6v5c0 1.7 3.1 3 7 3s7-1.3 7-3V6M5 11v5c0 1.7 3.1 3 7 3s7-1.3 7-3v-5" />
        </>
      )}
      {name === "check" && (
        <>
          <circle {...common} cx="12" cy="12" r="8" />
          <path {...common} d="m8.5 12 2.3 2.3 4.7-5" />
        </>
      )}
      {name === "route" && (
        <>
          <circle {...common} cx="6" cy="17" r="2" />
          <circle {...common} cx="18" cy="7" r="2" />
          <path {...common} d="M8 17h3a3 3 0 0 0 3-3v-4a3 3 0 0 1 3-3" />
        </>
      )}
      {name === "sliders" && (
        <>
          <path {...common} d="M4 7h5M13 7h7M4 17h9M17 17h3" />
          <circle {...common} cx="11" cy="7" r="2" />
          <circle {...common} cx="15" cy="17" r="2" />
        </>
      )}
      {name === "question" && (
        <>
          <circle {...common} cx="12" cy="12" r="8" />
          <path {...common} d="M9.8 9a2.4 2.4 0 0 1 4.6 1c0 1.8-2.4 2.1-2.4 4M12 17h.01" />
        </>
      )}
    </svg>
  );
}

function FlowArrow({ muted = false }: { muted?: boolean }) {
  return (
    <span className={muted ? styles.flowArrowMuted : styles.flowArrow} aria-hidden="true">
      <svg viewBox="0 0 48 20">
        <path d="M2 10h40" />
        <path d="m36 4 6 6-6 6" />
      </svg>
    </span>
  );
}

function PhoneFrame({
  src,
  alt,
  className = "",
}: {
  src: string;
  alt: string;
  className?: string;
}) {
  return (
    <div className={`${styles.phoneFrame} ${className}`}>
      <Image
        src={src}
        alt={alt}
        width={368}
        height={800}
        sizes="220px"
        loading={src === "/app-result.jpg" ? undefined : "eager"}
        priority={src === "/app-result.jpg"}
      />
    </div>
  );
}

export default function TechnologyPage() {
  return (
    <div className={styles.page}>
      <header className={styles.technologyNav}>
        <Link className={styles.brand} href="/" aria-label="오디버려 홈으로 이동">
          <Image src="/app-icon.png" alt="" width={42} height={42} priority />
          <span>오디버려</span>
        </Link>

        <nav className={styles.navLinks} aria-label="기술 설명 페이지 메뉴">
          <a href="#overview">개요</a>
          <a href="#scan">스캔 분석</a>
          <a href="#search">검색 분석</a>
          <a href="#guardrails">안전장치</a>
        </nav>

        <Link className={styles.homeLink} href="/">
          서비스 홈
          <span aria-hidden="true">↗</span>
        </Link>
      </header>

      <main>
        <section className={`${styles.slide} ${styles.hero}`} id="overview" aria-labelledby="overview-title">
          <div className={styles.heroCopy}>
            <h1 id="overview-title">AI가 답을 만드는 과정</h1>
            <p>
              사진과 검색어를 관찰하고,
              <br />
              검수된 규칙으로 배출 방법을 완성합니다.
            </p>
          </div>

          <div className={styles.heroArchitecture} aria-label="스캔과 검색 분석 구조 요약">
            <div className={styles.overviewNode}>
              <span className={styles.iconTile}><TechIcon name="camera" /></span>
              <div>
                <strong>사용자 입력</strong>
                <span>사진 또는 검색어</span>
              </div>
            </div>

            <FlowArrow />

            <div className={styles.overviewPaths}>
              <article>
                <span className={styles.pathIcon}><TechIcon name="scan" /></span>
                <div>
                  <strong>스캔</strong>
                  <span>사진의 관찰값을 구조화</span>
                </div>
              </article>
              <article>
                <span className={styles.pathIcon}><TechIcon name="search" /></span>
                <div>
                  <strong>검색</strong>
                  <span>검색어를 카탈로그 ID로 연결</span>
                </div>
              </article>
            </div>

            <FlowArrow />

            <div className={`${styles.overviewNode} ${styles.policyNode}`}>
              <span className={styles.iconTile}><TechIcon name="shield" /></span>
              <div>
                <strong>앱의 규칙</strong>
                <span>신뢰도·충돌·정책 검증</span>
              </div>
            </div>

            <FlowArrow />

            <div className={`${styles.overviewNode} ${styles.outputNode}`}>
              <span className={styles.iconTile}><TechIcon name="check" /></span>
              <div>
                <strong>검수된 배출 안내</strong>
                <span>경로 · 준비 순서 · 주의사항</span>
              </div>
            </div>
          </div>

          <div className={styles.heroBottom}>
            <p className={styles.coreStatement}>
              <TechIcon name="sparkles" />
              <strong>AI는 관찰하고</strong>
              <span>·</span>
              <strong>규칙은 결정합니다</strong>
            </p>
            <PhoneFrame
              src="/app-result.jpg"
              alt="오디버려의 스캔 결과 화면"
              className={styles.heroPhone}
            />
          </div>
        </section>

        <section className={`${styles.slide} ${styles.scanSlide}`} id="scan" aria-labelledby="scan-title">
          <div className={styles.sectionHeading}>
            <div>
              <span className={styles.sectionNumber}>01</span>
              <h2 id="scan-title">스캔 AI 분석</h2>
            </div>
            <p>
              사진 한 장이 배출 안내가 되기까지,
              <br />
              관찰과 결정의 역할을 분리합니다.
            </p>
          </div>

          <div className={styles.scanPipeline}>
            <div className={styles.scanSource}>
              <span>사진 입력</span>
              <PhoneFrame src="/app-scan.jpg" alt="오디버려 스캔 시작 화면" />
            </div>

            <FlowArrow />

            <div className={styles.parallelGroup}>
              <p className={styles.groupLabel}>동시에 분석</p>
              <article className={styles.branchNode}>
                <span className={styles.branchIcon}><TechIcon name="scan" /></span>
                <div>
                  <strong>Vision OCR</strong>
                  <em>기기 내 표시 인식</em>
                  <p>중앙 90% 영역에서 한·영 분리배출 표기를 읽어 별도 신호로 만듭니다.</p>
                </div>
              </article>

              <article className={`${styles.branchNode} ${styles.geminiNode}`}>
                <span className={styles.branchIcon}><TechIcon name="sparkles" /></span>
                <div>
                  <strong>Gemini</strong>
                  <em>구조화된 사진 관찰</em>
                  <p>물체·재질·형태·오염·위험·촬영 상태를 JSON으로 관찰합니다.</p>
                  <div className={styles.inlineSteps}>
                    <span>관찰 JSON</span>
                    <b aria-hidden="true">→</b>
                    <span>Swift 규칙 매핑</span>
                  </div>
                  <small>불명확할 때만 정밀 모델로 다시 관찰</small>
                </div>
              </article>
            </div>

            <FlowArrow />

            <article className={`${styles.decisionNode} ${styles.emphasisNode}`}>
              <span className={styles.largeNodeIcon}><TechIcon name="shield" /></span>
              <strong>최종 신뢰 게이트</strong>
              <em>OCR · 사진 관찰 · 촬영 품질</em>
              <p>근거별 최소 신뢰도와 충돌을 확인하고, 부족하면 판단을 보류합니다.</p>
            </article>

            <FlowArrow />

            <article className={styles.decisionNode}>
              <span className={styles.largeNodeIcon}><TechIcon name="database" /></span>
              <strong>정책 카탈로그</strong>
              <em>배출 경로 · 준비 순서</em>
              <p>AI 자유 서술이 아닌 앱 내부의 검수된 정책으로 최종 안내를 조립합니다.</p>
            </article>

            <FlowArrow />

            <div className={styles.scanResult}>
              <span>결과 안내</span>
              <PhoneFrame src="/app-result.jpg" alt="오디버려 스캔 분석 결과 화면" />
            </div>
          </div>

          <div className={styles.scanTakeaway}>
            <strong>AI가 배출 규칙을 만들지 않습니다.</strong>
            <span>AI는 보이는 사실을 정리하고, 최종 판단과 안내는 앱의 규칙이 맡습니다.</span>
          </div>
        </section>

        <section className={`${styles.slide} ${styles.searchSlide}`} id="search" aria-labelledby="search-title">
          <div className={styles.sectionHeading}>
            <div>
              <span className={styles.sectionNumber}>02</span>
              <h2 id="search-title">검색 AI 분석</h2>
            </div>
            <p>
              먼저 로컬 카탈로그에서 찾고,
              <br />
              없을 때만 AI가 제한적으로 보조합니다.
            </p>
          </div>

          <div className={styles.searchCanvas}>
            <PhoneFrame src="/app-search.jpg" alt="오디버려 분리배출 검색 화면" className={styles.searchPhone} />

            <div className={styles.searchGraph}>
              <p className={styles.primaryLabel}><span>1</span> 로컬 우선 검색</p>
              <ol className={styles.primaryFlow}>
                <li>
                  <span className={styles.searchStepIcon}><TechIcon name="search" /></span>
                  <strong>검색어 입력</strong>
                  <small>예: 보조배터리</small>
                </li>
                <li aria-hidden="true"><FlowArrow /></li>
                <li>
                  <span className={styles.searchStepIcon}><TechIcon name="sliders" /></span>
                  <strong>정규화</strong>
                  <small>띄어쓰기·기호 보정</small>
                </li>
                <li aria-hidden="true"><FlowArrow /></li>
                <li className={styles.catalogStep}>
                  <span className={styles.searchStepIcon}><TechIcon name="database" /></span>
                  <strong>검수 카탈로그</strong>
                  <small>정확 · 접두 · 유사어 점수화</small>
                </li>
                <li aria-hidden="true"><FlowArrow /></li>
                <li>
                  <span className={styles.searchStepIcon}><TechIcon name="route" /></span>
                  <strong>상품 형태 선택</strong>
                  <small>실물과 가까운 형태 확인</small>
                </li>
                <li aria-hidden="true"><FlowArrow /></li>
                <li className={styles.searchOutput}>
                  <span className={styles.searchStepIcon}><TechIcon name="check" /></span>
                  <strong>검수된 안내</strong>
                  <small>경로 · 부분 · 준비 방법</small>
                </li>
              </ol>

              <div className={styles.fallbackFlow}>
                <p className={styles.fallbackLabel}><span>2</span> 결과가 없고 사용자가 선택한 경우에만</p>
                <div className={styles.fallbackRail}>
                  <div className={styles.userAction}>
                    <TechIcon name="sparkles" />
                    <strong>AI로 다시 찾아보기</strong>
                  </div>
                  <FlowArrow muted />
                  <div>
                    <TechIcon name="database" />
                    <strong>캐시 확인</strong>
                    <small>최근 매핑 우선</small>
                  </div>
                  <FlowArrow muted />
                  <div>
                    <TechIcon name="sparkles" />
                    <strong>Gemini ID 매핑</strong>
                    <small>허용된 상품군만</small>
                  </div>
                  <FlowArrow muted />
                  <div>
                    <TechIcon name="shield" />
                    <strong>신뢰도 게이트</strong>
                    <small>70 미만·없는 ID 거절</small>
                  </div>
                  <FlowArrow muted />
                  <div className={styles.returnToCatalog}>
                    <TechIcon name="database" />
                    <strong>같은 카탈로그로 복귀</strong>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <p className={styles.searchTakeaway}>
            <TechIcon name="check" />
            <strong>AI는 검색어를 해석하고, 배출 정보는 카탈로그에서 가져옵니다.</strong>
          </p>
        </section>

        <section className={`${styles.slide} ${styles.guardrailSlide}`} id="guardrails" aria-labelledby="guardrails-title">
          <div className={styles.guardrailHeading}>
            <h2 id="guardrails-title">정확도를 지키는 네 가지 경계</h2>
            <p>빠른 답보다, 설명 가능한 답을 우선합니다.</p>
          </div>

          <div className={styles.guardrailField}>
            <div className={styles.guardrailBrand} aria-hidden="true">
              <Image src="/app-icon.png" alt="" width={1254} height={1254} sizes="118px" />
            </div>
            {safeguards.map((item, index) => (
              <article className={styles.guardrailItem} key={item.title} data-position={index + 1}>
                <span><TechIcon name={item.icon} /></span>
                <div>
                  <h3>{item.title}</h3>
                  <p>{item.description}</p>
                </div>
              </article>
            ))}
          </div>

          <ul className={styles.stackList} aria-label="오디버려 분석 기술 스택">
            {stack.map((item) => <li key={item}>{item}</li>)}
          </ul>

          <div className={styles.closingLine}>
            <p>관찰은 AI에게, 기준은 검수된 규칙에게.</p>
            <Link href="/">
              오디버려 홈으로 돌아가기
              <span aria-hidden="true">→</span>
            </Link>
          </div>
        </section>
      </main>
    </div>
  );
}
