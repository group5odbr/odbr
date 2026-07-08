import SwiftUI
import UIKit

struct ScanView: View {
    @Binding var selectedTab: AppTab

    @State private var capturedImage: UIImage?
    @State private var result: DisposalResult?
    @State private var isCameraPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    header
                    scanSurface

                    if let result {
                        ResultCard(
                            result: Binding(
                                get: { result },
                                set: { self.result = $0 }
                            ),
                            onShowNephron: { selectedTab = .nephron }
                        )
                    } else {
                        ReadyCard()
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraCaptureView { image in
                capturedImage = image
                withAnimation(.easeInOut(duration: 0.22)) {
                    result = DisposalResult.sample()
                }
            }
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("어디버려")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)

            Text("사진 한 장으로 지금 버릴 방법을 바로 확인해요.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.top, AppTheme.Spacing.lg)
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
                        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: 280)
                        .clipped()
                } else {
                    EmptyScanPreview()
                }

                ScanFrameOverlay()
                    .padding(AppTheme.Spacing.xl)
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.scan, style: .continuous))

            Button {
                startCamera()
            } label: {
                Label(capturedImage == nil ? "사진 찍고 분석하기" : "다시 촬영하기", systemImage: "camera.fill")
            }
            .buttonStyle(PrimaryActionButtonStyle())
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
            isCameraPresented = true
            return
        }

        withAnimation(.easeInOut(duration: 0.22)) {
            result = DisposalResult.sample()
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

                Text("분리배출 마크가 보이면 더 정확해져요")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ScanFrameOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
            .stroke(AppTheme.card.opacity(0.96), lineWidth: 3)
            .overlay(alignment: .topLeading) {
                Text("MARK + ITEM")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.deepGreen)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
                    .padding(AppTheme.Spacing.md)
            }
    }
}

private struct ReadyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                IconTile(systemName: "magnifyingglass.circle.fill")
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("마크가 우선이에요")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("재질명이 보이면 사물 추정보다 먼저 반영합니다.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .utilityCard()
    }
}
