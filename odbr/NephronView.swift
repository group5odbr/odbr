import SwiftUI

nonisolated struct NephronContext: Equatable, Sendable {
    let itemTitle: String
    let route: DisposalRoute
}

struct NephronView: View {
    let context: NephronContext?
    let onShowInformation: () -> Void

    init(
        context: NephronContext? = nil,
        onShowInformation: @escaping () -> Void = {}
    ) {
        self.context = context
        self.onShowInformation = onShowInformation
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    ScreenHeader(
                        title: "네프론",
                        subtitle: "넣을 수 있는 품목과 기기 운영 상태를 확인한 뒤 이용해요.",
                        onShowInformation: onShowInformation
                    )

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        if let context {
                            selectedItemCard(context)
                        }

                        introductionCard
                        eligibleItemsCard
                        preparationCard
                        excludedItemsCard
                        officialLinkCard
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tabScreenPadding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("nephron.screen")
        }
    }

    private func selectedItemCard(_ context: NephronContext) -> some View {
        let eligibility = DisposalPolicyCatalog.policy(for: context.route).nephronEligibility
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                IconTile(systemName: context.route.symbolName)
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("방금 확인한 품목")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(context.itemTitle)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(eligibility == .likelyEligible ? "넣을 수 있는 품목으로 보여요. 이용할 기기의 조건을 한 번 더 확인하세요." : "기기마다 받을 수 있는 품목이 달라요. 이용 전에 확인해 주세요.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .utilityCard(highlighted: true)
        .accessibilityIdentifier("nephron.selectedItem")
    }

    private var introductionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                IconTile(systemName: "arrow.3.trianglepath")
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("네프론이란?")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("수퍼빈이 운영하는 무인 회수기예요. 투명 음료 페트병과 음료 캔 등을 넣을 수 있고, 기기마다 받는 품목이 달라요.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .utilityCard()
    }

    private var eligibleItemsCard: some View {
        guideCard(
            title: "이용 가능성이 높은 품목",
            rows: [
                NephronGuideRow(title: "투명 음료 페트병", detail: "라벨을 떼고 내용물을 비운 투명 음료병", systemImage: "drop.fill"),
                NephronGuideRow(title: "음료 캔", detail: "이용할 기기가 음료 캔을 받는 경우", systemImage: "cylinder.fill")
            ]
        )
    }

    private var preparationCard: some View {
        guideCard(
            title: "이용 전에 확인하세요",
            rows: [
                NephronGuideRow(title: "내용물 비우기", detail: "음료와 이물질을 남기지 않아요.", systemImage: "drop.degreesign.slash.fill"),
                NephronGuideRow(title: "페트병 라벨 떼기", detail: "라벨을 뗀 뒤 넣어요.", systemImage: "tag.slash.fill"),
                NephronGuideRow(title: "기기 상태 확인", detail: "방문 전에 운영 중인지, 내 품목을 받는지 확인해요.", systemImage: "checklist")
            ]
        )
    }

    private var excludedItemsCard: some View {
        guideCard(
            title: "이용이 어려운 대표 품목",
            rows: [
                NephronGuideRow(title: "통조림·위험한 캔", detail: "통조림캔, 부탄가스, 살충제, 기름이 남은 용기", systemImage: "exclamationmark.triangle.fill"),
                NephronGuideRow(title: "넣을 수 없는 페트 제품", detail: "색 있는 병, 식품 용기·트레이, 유리병", systemImage: "xmark.circle.fill"),
                NephronGuideRow(title: "심하게 더럽거나 찌그러진 품목", detail: "기기가 모양을 알아보기 어려운 상태", systemImage: "nosign")
            ],
            warning: true
        )
    }

    private func guideCard(title: String, rows: [NephronGuideRow], warning: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)

            ForEach(rows) { row in
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    Image(systemName: row.systemImage)
                        .foregroundStyle(warning ? AppTheme.warning : AppTheme.accent)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(row.title)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)
                        Text(row.detail)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .utilityCard(warning: warning)
    }

    private var officialLinkCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                IconTile(systemName: "mappin.and.ellipse")
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("가까운 회수기 찾기")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("수퍼빈 공식 위치 검색에서 운영 여부와 기기마다 받는 품목을 확인하세요.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Link(destination: URL(string: "https://www.superbin.co.kr/map")!) {
                Label("공식 위치 검색 열기", systemImage: "arrow.up.right")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("nephron.officialLink")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .utilityCard(highlighted: true)
    }
}

private struct NephronGuideRow: Identifiable {
    let title: String
    let detail: String
    let systemImage: String

    var id: String { title }
}

#Preview {
    NephronView(context: NephronContext(itemTitle: "투명 음료 페트병", route: .recyclable(.clearPETBottle)))
}
