import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct ScanView: View {
    @Binding var selectedTab: AppTab
    @Binding var nephronContext: NephronContext?
    let onShowInformation: () -> Void

    @AppStorage("odbr.aiImageAnalysisConsent.v1") private var hasImageAnalysisConsent = false
    @State private var capturedImage: UIImage?
    @State private var result: DisposalResult?
    @State private var analysisReport: AnalysisReport?
    @State private var isCameraPresented = false
    @State private var isAnalyzing = false
    @State private var presentedReport: AnalysisReport?
    @State private var scanNotice: String?
    @State private var cameraAccessDenied = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var consentRequest: ImageAnalysisConsentRequest?
    @State private var pendingImage: UIImage?
    @State private var analysisTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    ScreenHeader(
                        title: "오디버려",
                        subtitle: "사진 한 장으로 지금 버릴 방법을 바로 확인해요.",
                        onShowInformation: onShowInformation
                    )
                    scanSurface

                    if isAnalyzing {
                        AnalysisStatusCard(onCancel: cancelAnalysis)
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
                                onShowNephron: {
                                    nephronContext = NephronContext(itemTitle: result.title, route: result.route)
                                    selectedTab = .nephron
                                }
                            )

                            if result.isUncertain, let capturedImage {
                                ScanRecoveryActions(
                                    onRetry: { analyze(capturedImage) },
                                    onSearch: { selectedTab = .search }
                                )
                            }

                            if analysisReport != nil {
                                AnalysisReportButton {
                                    presentedReport = analysisReport
                                }
                            }
                        }
                    } else if let scanNotice {
                        ScanNoticeCard(
                            message: scanNotice,
                            showsSettingsAction: cameraAccessDenied,
                            onOpenSettings: openSettings,
                            onSearch: { selectedTab = .search }
                        )
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
                handleSelectedImage(image)
            }
            .ignoresSafeArea()
        }
        .sheet(item: $presentedReport) { report in
            AnalysisReportSheet(report: report)
        }
        .sheet(item: $consentRequest) { _ in
            ImageAnalysisConsentSheet(
                onAgree: grantConsentAndAnalyze,
                onUseSearch: {
                    pendingImage = nil
                    selectedTab = .search
                }
            )
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                guard
                    let data = try? await item.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                else {
                    scanNotice = "선택한 사진을 불러오지 못했어요. 다른 사진을 선택해 주세요."
                    return
                }
                handleSelectedImage(image)
            }
        }
        .onChange(of: selectedTab) { _, tab in
            if tab != .scan {
                cancelAnalysis()
            }
        }
        .onDisappear {
            cancelAnalysis()
        }
        .onAppear {
            applyUITestScenarioIfNeeded()
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
                Text("선택한 사진은 Gemini가 분석해요.")
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

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("사진에서 선택하기", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(isAnalyzing)
            .accessibilityIdentifier("scan.photoPicker")
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
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraAccessDenied = false
            scanNotice = "이 환경에서는 카메라를 사용할 수 없어요. 사진을 선택하거나 품목 검색을 이용해 주세요."
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentCamera()
        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted {
                    presentCamera()
                } else {
                    showCameraPermissionNotice()
                }
            }
        case .denied, .restricted:
            showCameraPermissionNotice()
        @unknown default:
            showCameraPermissionNotice()
        }
    }

    private func presentCamera() {
        cameraAccessDenied = false
        scanNotice = nil
        isCameraPresented = true
    }

    private func showCameraPermissionNotice() {
        withAnimation(.easeInOut(duration: 0.22)) {
            cameraAccessDenied = true
            scanNotice = "카메라 권한이 꺼져 있어요. 설정에서 허용하거나 사진 선택·품목 검색을 이용해 주세요."
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var actionTitle: String {
        if isAnalyzing {
            return "분석 중"
        }

        return capturedImage == nil ? "사진 찍고 분석하기" : "다시 촬영하기"
    }

    private func handleSelectedImage(_ image: UIImage) {
        capturedImage = image
        cameraAccessDenied = false
        scanNotice = nil

        guard hasImageAnalysisConsent else {
            pendingImage = image
            consentRequest = ImageAnalysisConsentRequest()
            return
        }

        analyze(image)
    }

    private func grantConsentAndAnalyze() {
        hasImageAnalysisConsent = true
        consentRequest = nil
        guard let pendingImage else { return }
        self.pendingImage = nil
        analyze(pendingImage)
    }

    private func analyze(_ image: UIImage) {
        analysisTask?.cancel()
        result = nil
        analysisReport = nil
        scanNotice = nil
        isAnalyzing = true

        analysisTask = Task {
            let report = await WasteRecognitionService.shared.analyzeWithReport(image)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.22)) {
                result = report.result
                analysisReport = report
                isAnalyzing = false
            }
        }
    }

    private func cancelAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
        isAnalyzing = false
    }

    private func applyUITestScenarioIfNeeded() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard
            let flagIndex = arguments.firstIndex(of: "-uiTestScenario"),
            arguments.indices.contains(flagIndex + 1)
        else { return }

        switch arguments[flagIndex + 1] {
        case "correction" where result == nil:
            result = DisposalResult(
                category: .plastic,
                source: .multimodalAI,
                confidence: 82,
                evidences: [DisposalEvidence(title: "사진에서 확인한 내용", detail: "플라스틱 재질과 용기 모양을 확인했어요.")],
                candidates: [.vinyl, .paperPack, .can]
            )
        case "consent" where consentRequest == nil:
            consentRequest = ImageAnalysisConsentRequest()
        case "cameraDenied" where scanNotice == nil:
            cameraAccessDenied = true
            scanNotice = "카메라 권한이 꺼져 있어요. 설정에서 허용하거나 사진 선택·품목 검색을 이용해 주세요."
        case "networkFailure" where result == nil:
            capturedImage = UIImage(systemName: "shippingbox.fill")
            result = DisposalResult(
                route: .unknown,
                source: .localFallback,
                confidence: 0,
                evidences: [DisposalEvidence(title: "다시 확인이 필요해요", detail: "네트워크 연결 문제로 분석을 완료하지 못했어요.")],
                candidates: [.plastic, .paper]
            )
        default:
            break
        }
        #endif
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
                    Text("물건의 모양·재질·분리배출 표시를 함께 보고, 잘 모르겠으면 억지로 답하지 않아요.")
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
    let showsSettingsAction: Bool
    let onOpenSettings: () -> Void
    let onSearch: () -> Void

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

            if showsSettingsAction {
                Button("설정에서 카메라 허용", action: onOpenSettings)
                    .buttonStyle(PrimaryActionButtonStyle())
            }

            Button("품목 검색 사용", action: onSearch)
                .buttonStyle(SecondaryActionButtonStyle())
        }
        .utilityCard()
    }
}

private struct AnalysisStatusCard: View {
    let onCancel: () -> Void

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
                    Text("사진 속 물건의 모양, 재질, 분리배출 표시를 함께 보고 있어요.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Button("분석 취소", action: onCancel)
                .buttonStyle(SecondaryActionButtonStyle())
                .accessibilityIdentifier("scan.cancel")
        }
        .utilityCard()
    }
}

private struct ScanRecoveryActions: View {
    let onRetry: () -> Void
    let onSearch: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppTheme.Spacing.sm) { actions }
            VStack(spacing: AppTheme.Spacing.sm) { actions }
        }
    }

    @ViewBuilder
    private var actions: some View {
        Button("같은 사진 다시 분석", action: onRetry)
            .buttonStyle(SecondaryActionButtonStyle())
            .accessibilityIdentifier("scan.retry")
        Button("품목 검색", action: onSearch)
            .buttonStyle(SecondaryActionButtonStyle())
            .accessibilityIdentifier("scan.searchFallback")
    }
}

private struct ImageAnalysisConsentRequest: Identifiable {
    let id = UUID()
}

private struct ImageAnalysisConsentSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAgree: () -> Void
    let onUseSearch: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                IconTile(systemName: "lock.shield.fill")
                Text("사진 분석 전 확인해 주세요")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                Text("사진 속 물건과 재질을 확인하기 위해 사진이 Google Gemini로 전송돼요. 주소, 영수증, 얼굴 등 개인정보가 찍히지 않았는지 확인해 주세요.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button("동의하고 사진 분석") {
                    onAgree()
                    dismiss()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("consent.agree")

                Button("사진 없이 검색") {
                    onUseSearch()
                    dismiss()
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .accessibilityIdentifier("consent.search")
            }
            .padding(AppTheme.Spacing.xl)
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct AnalysisReportButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("왜 이렇게 안내했나요?", systemImage: "doc.text.magnifyingglass")
        }
        .buttonStyle(SecondaryActionButtonStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("scan.report")
    }
}
