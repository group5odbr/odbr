import SwiftUI

struct ResultCard: View {
    @Binding var result: DisposalResult
    let onShowNephron: () -> Void

    @State private var confirmedResultID: UUID?
    @State private var correctionRequest: CorrectionRequest?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            resultHeader
            evidenceChips
            preparationSteps
            warnings
            correctionChips

            if result.canUseNephron {
                Button(action: onShowNephron) {
                    Label("네프론 위치 보기", systemImage: "mappin.and.ellipse")
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .accessibilityIdentifier("result.nephron")
            }
        }
        .utilityCard(
            highlighted: result.source != .userCorrection && !result.isUncertain,
            warning: result.isUncertain
        )
        .sheet(item: $correctionRequest) { request in
            CorrectionSheet(result: request.result) { route in
                correctResult(to: route)
            }
        }
        .onChange(of: result.id) { _, newID in
            if confirmedResultID != newID {
                confirmedResultID = nil
            }
        }
    }

    private var resultHeader: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            IconTile(
                systemName: result.route.symbolName,
                tint: result.isUncertain ? AppTheme.warning : AppTheme.accent
            )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(result.title)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(resultSubtitle)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
        }
    }

    private var evidenceChips: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            ForEach(result.evidences) { evidence in
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: result.isUncertain ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(result.isUncertain ? AppTheme.warning : AppTheme.deepGreen)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(evidence.title)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(result.isUncertain ? AppTheme.warning : AppTheme.deepGreen)
                        Text(evidence.detail)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(result.isUncertain ? AppTheme.card.opacity(0.72) : AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
            }
        }
    }

    private var preparationSteps: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(result.isUncertain ? "다시 찍는 방법" : "버리기 전에")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)

            ForEach(displayedSteps, id: \.self) { step in
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: result.isUncertain ? "arrow.clockwise.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(result.isUncertain ? AppTheme.warning : AppTheme.deepGreen)
                        .accessibilityHidden(true)
                    Text(step)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
        }
    }

    @ViewBuilder
    private var warnings: some View {
        let policy = DisposalPolicyCatalog.policy(for: result.route)
        if !policy.warnings.isEmpty || policy.localVariationRequired {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("주의사항")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)

                ForEach(policy.warnings, id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if policy.localVariationRequired {
                    Label("사는 곳마다 배출 방법이 다를 수 있으니 우리 동네 안내를 먼저 확인해 주세요.", systemImage: "building.columns.fill")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var correctionChips: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("정확했나요?")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    confirmationButton
                    correctionMenu
                }

                VStack(spacing: AppTheme.Spacing.sm) {
                    confirmationButton
                    correctionMenu
                }
            }

            if result.isUncertain {
                Text("원하는 결과가 없어도 ‘아니에요’를 눌러 전체 목록에서 고를 수 있어요.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var resultSubtitle: String {
        if result.isUncertain {
            return "정확히 알기 어려워 다시 확인이 필요해요"
        }

        if result.source == .userCorrection {
            return "사용자가 직접 선택한 배출 종류"
        }

        return result.source.title
    }

    private var displayedSteps: [String] {
        result.specificSteps.isEmpty ? result.category.guideSteps : result.specificSteps
    }

    private var isConfirmed: Bool {
        confirmedResultID == result.id
    }

    private var confirmationButton: some View {
        Button {
            confirmedResultID = result.id
        } label: {
            Label(isConfirmed ? "확인했어요" : "맞아요", systemImage: "hand.thumbsup.fill")
        }
        .buttonStyle(SecondaryActionButtonStyle())
        .disabled(isConfirmed)
        .accessibilityIdentifier("result.confirm")
    }

    private var correctionMenu: some View {
        Button {
            correctionRequest = CorrectionRequest(result: result)
        } label: {
            Label("아니에요", systemImage: "hand.thumbsdown.fill")
        }
        .buttonStyle(SecondaryActionButtonStyle())
        .accessibilityIdentifier("result.correct")
    }

    private func correctResult(to route: DisposalRoute) {
        withAnimation(.easeInOut(duration: 0.18)) {
            let correctedResult = result.corrected(to: route)
            result = correctedResult
            confirmedResultID = nil
        }
    }
}

private struct CorrectionRequest: Identifiable {
    let id = UUID()
    let result: DisposalResult
}

private struct CorrectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let result: DisposalResult
    let onSelect: (DisposalRoute) -> Void

    private var ranked: [CorrectionCandidate] {
        CorrectionCandidateBuilder.ranked(for: result)
    }

    private var remaining: [DisposalRoute] {
        CorrectionCandidateBuilder.allRoutes(excluding: result)
    }

    var body: some View {
        NavigationStack {
            List {
                if !ranked.isEmpty {
                    Section("AI가 찾은 다음 후보") {
                        ForEach(ranked) { candidate in
                            routeButton(candidate.route, reason: candidate.reason.title)
                        }
                    }
                }

                Section("전체 버리는 방법") {
                    ForEach(remaining) { route in
                        routeButton(route, reason: DisposalPolicyCatalog.policy(for: route).summary)
                    }
                }
            }
            .navigationTitle("다른 방법 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .accessibilityIdentifier("result.correctionSheet")
        }
    }

    private func routeButton(_ route: DisposalRoute, reason: String) -> some View {
        Button {
            onSelect(route)
            dismiss()
        } label: {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                Image(systemName: route.symbolName)
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(route.title)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityLabel("\(route.title), \(reason)")
        .accessibilityIdentifier("result.correction.\(route.id)")
    }
}
