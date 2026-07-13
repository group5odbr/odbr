import SwiftUI

struct ResultCard: View {
    @Binding var result: DisposalResult
    let onShowNephron: () -> Void

    @State private var confirmedResultID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            resultHeader
            evidenceChips
            preparationSteps
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
    }

    private var resultHeader: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            IconTile(systemName: result.category.symbolName, tint: result.category.tint)

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
            Text(result.isUncertain ? "다시 촬영하는 방법" : "배출 전 처리")
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
                Text("후보에 없어도 ‘아니에요’를 눌러 전체 배출 종류에서 선택할 수 있어요.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var resultSubtitle: String {
        if result.isUncertain {
            return "오답 방지를 위해 결과를 확정하지 않았어요"
        }

        if result.source == .userCorrection {
            return "사용자가 직접 선택한 배출 종류"
        }

        return "\(result.source.title) · 신뢰도 \(result.confidence)%"
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
        Menu {
            ForEach(DisposalCategory.disposalCases) { candidate in
                Button(candidate.title) {
                    correctResult(to: candidate)
                }
            }
        } label: {
            Label("아니에요", systemImage: "hand.thumbsdown.fill")
        }
        .buttonStyle(SecondaryActionButtonStyle())
        .accessibilityIdentifier("result.correct")
    }

    private func correctResult(to category: DisposalCategory) {
        withAnimation(.easeInOut(duration: 0.18)) {
            let correctedResult = result.corrected(to: category)
            result = correctedResult
            confirmedResultID = correctedResult.id
        }
    }
}
