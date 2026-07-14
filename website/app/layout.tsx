import type { Metadata } from "next";
import "./globals.css";

const title = "오디버려 — 사진 한 장으로 확인하는 분리배출 도우미";
const description =
  "사진 분석, 품목 검색, 네프론 안내까지. 버릴 곳이 헷갈릴 때 오디버려가 배출 방법과 준비 순서를 알려드려요.";

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ??
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : "http://localhost:3000");

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title,
  description,
  icons: {
    icon: "/app-icon.png",
    apple: "/app-icon.png",
  },
  openGraph: {
    type: "website",
    locale: "ko_KR",
    title,
    description,
    siteName: "오디버려",
    images: [
      {
        url: "/og.png",
        width: 1731,
        height: 909,
        alt: "오디버려 — 사진 한 장으로 확인하는 분리배출 도우미",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title,
    description,
    images: ["/og.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
