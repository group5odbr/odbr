import SwiftUI

struct ResultCard: View {
    @Binding var result: DisposalResult
    let onShowNephron: () -> Void

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
            }
        }
        .utilityCard(highlighted: result.source != .userCorrection)
    }

    private var resultHeader: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            IconTile(systemName: result.category.symbolName, tint: result.category.tint)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(result.title)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(2)

                Text("\(result.source.title) · 신뢰도 \(result.confidence)%")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
        }
    }

    private var evidenceChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(result.evidences) { evidence in
                    Text("\(evidence.title) \(evidence.detail)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.deepGreen)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
                }
            }
        }
    }

    private var preparationSteps: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("배출 전 처리")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)

            ForEach(result.category.guideSteps, id: \.self) { step in
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text(step)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
        }
    }

    private var correctionChips: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("결과가 다르면")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(result.candidates) { candidate in
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                result = result.corrected(to: candidate)
                            }
                        } label: {
                            Text(candidate.title)
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                    }
                }
            }
        }
    }
}
