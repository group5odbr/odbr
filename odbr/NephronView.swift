import SwiftUI

struct NephronView: View {
    private let items = NephronItem.examples

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    ScreenHeader(
                        title: "네프론",
                        subtitle: "페트병과 캔은 회수기 이용 가능성을 함께 확인해요."
                    )
                    mapCard
                    acceptedItems
                    officialLinkCard
                }
                .tabScreenPadding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("nephron.screen")
        }
    }

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .fill(AppTheme.mintSurface)

                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)

                    Text("가까운 회수기 찾기")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                        .multilineTextAlignment(.center)

                    Text("현재 운영 중인 회수기 위치는 수퍼빈 공식 안내에서 확인할 수 있어요.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.Spacing.xl)
            }
            .frame(height: 220)

            HStack(spacing: AppTheme.Spacing.md) {
                NephronMetric(title: "대상", value: "페트 · 캔")
                NephronMetric(title: "확인", value: "공식 안내")
            }
        }
        .utilityCard()
    }

    private var acceptedItems: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("회수 가능성이 높은 품목")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)

            ForEach(items) { item in
                HStack(spacing: AppTheme.Spacing.md) {
                    IconTile(systemName: item.systemImage)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(item.title)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)

                        Text(item.detail)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            }
        }
        .utilityCard()
    }

    private var officialLinkCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                IconTile(systemName: "safari")
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("수퍼빈 공식 안내")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("기기별 운영 여부와 위치를 방문 전에 확인해 주세요.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            if let superbinURL = URL(string: "https://www.superbin.co.kr") {
                Link(destination: superbinURL) {
                    Label("공식 사이트 열기", systemImage: "arrow.up.right")
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("nephron.officialLink")
            }
        }
        .utilityCard(highlighted: true)
    }
}

private struct NephronMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
    }
}

private struct NephronItem: Identifiable {
    let title: String
    let detail: String
    let systemImage: String

    var id: String { title }

    static let examples = [
        NephronItem(title: "투명 페트병", detail: "내용물을 비우고 라벨을 분리해요.", systemImage: "drop.fill"),
        NephronItem(title: "음료 캔", detail: "내용물을 비우고 가능하면 압착해요.", systemImage: "circle.fill")
    ]
}
