import SwiftUI
import UIKit

struct ScanView: View {
    @Binding var selectedTab: AppTab

    @State private var capturedImage: UIImage?
    @State private var result: DisposalResult?
    @State private var analysisReport: AnalysisReport?
    @State private var isCameraPresented = false
    @State private var isAnalyzing = false
    @State private var presentedReport: AnalysisReport?
    @State private var scanNotice: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    ScreenHeader(
                        title: "어디버려",
                        subtitle: "사진 한 장으로 지금 버릴 방법을 바로 확인해요."
                    )
                    scanSurface

                    if isAnalyzing {
                        AnalysisStatusCard()
                    } else if let result {
                        VStack(spacing: AppTheme.Spacing.md) {
                            ResultCard(
                                result: Binding(
                                    get: { result },
                                    set: { updatedResult in
                                        self.result = updatedResult
                                        if let analysisReport {
                                            self.analysisReport = analysisReport.replacingResult(updatedResult)
                                        }
                                    }
                                ),
                                onShowNephron: { selectedTab = .nephron }
                            )

                            if analysisReport != nil {
                                AnalysisReportButton {
                                    presentedReport = analysisReport
                                }
                            }
                        }
                    } else if let scanNotice {
                        ScanNoticeCard(message: scanNotice)
                    } else {
                        ReadyCard()
                    }
                }
                .tabScreenPadding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("scan.screen")
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraCaptureView { image in
                analyze(image)
            }
            .ignoresSafeArea()
        }
        .sheet(item: $presentedReport) { report in
            AnalysisReportSheet(report: report)
        }
    }

    private var scanSurface: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.scan, style: .continuous)
                    .fill(AppTheme.mintSurface)

                if let capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .accessibilityLabel("촬영한 쓰레기 사진")
                } else {
                    EmptyScanPreview()
                }

                ScanFrameOverlay()
                    .padding(AppTheme.Spacing.xl)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(minHeight: 240)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.scan, style: .continuous))

            Label {
                Text("중앙 촬영 영역은 Firebase AI 판정을 위해 전송돼요.")
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .accessibilityHidden(true)
            }
            .font(.system(.caption, design: .rounded))
            .foregroundStyle(AppTheme.secondaryText)

            Button {
                startCamera()
            } label: {
                Label(actionTitle, systemImage: isAnalyzing ? "hourglass" : "camera.fill")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(isAnalyzing)
            .accessibilityIdentifier("scan.capture")
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.scan, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.scan, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
        .shadow(color: AppTheme.deepGreen.opacity(0.08), radius: 24, x: 0, y: 14)
    }

    private func startCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            scanNotice = nil
            isCameraPresented = true
            return
        }

        withAnimation(.easeInOut(duration: 0.22)) {
            scanNotice = "이 환경에서는 카메라를 사용할 수 없어요. 실기기에서 촬영해 분석해 주세요."
        }
    }

    private var actionTitle: String {
        if isAnalyzing {
            return "분석 중"
        }

        return capturedImage == nil ? "사진 찍고 분석하기" : "다시 촬영하기"
    }

    private func analyze(_ image: UIImage) {
        capturedImage = image
        result = nil
        analysisReport = nil
        scanNotice = nil
        isAnalyzing = true

        Task {
            let report = await WasteRecognitionService.shared.analyzeWithReport(image)
            withAnimation(.easeInOut(duration: 0.22)) {
                result = report.result
                analysisReport = report
                isAnalyzing = false
            }
        }
    }
}

private struct EmptyScanPreview: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "viewfinder")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("중앙에 물체를 맞춰주세요")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("물체 하나를 담고, 마크가 있다면 함께 보이게 해주세요")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct ScanFrameOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
            .stroke(AppTheme.card.opacity(0.96), lineWidth: 3)
            .overlay(alignment: .topLeading) {
                Text("물체 + 보이는 마크")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.deepGreen)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
                    .padding(AppTheme.Spacing.md)
            }
            .accessibilityHidden(true)
    }
}

private struct ReadyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                IconTile(systemName: "magnifyingglass.circle.fill")
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("한 번에 하나만 선명하게 찍어주세요")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("물체·재질·표기를 함께 확인하고, 근거가 부족하면 결과를 확정하지 않아요.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .utilityCard()
        .accessibilityElement(children: .combine)
    }
}

private struct ScanNoticeCard: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                IconTile(systemName: "camera.badge.ellipsis")
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("촬영이 필요해요")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(message)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .utilityCard()
    }
}

private struct AnalysisStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                ProgressView()
                    .tint(AppTheme.deepGreen)
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("이미지 분석 중")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("사진의 물체, 재질, 분리배출 표시를 함께 확인하고 있어요.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .utilityCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("이미지 분석 중. 사진의 물체, 재질, 분리배출 표시를 확인하고 있습니다.")
    }
}

private struct AnalysisReportButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("분석 근거 보기", systemImage: "doc.text.magnifyingglass")
        }
        .buttonStyle(SecondaryActionButtonStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("scan.report")
    }
}
