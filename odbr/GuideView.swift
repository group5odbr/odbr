import SwiftUI

struct GuideView: View {
    @State private var searchText = ""

    private var categories: [DisposalCategory] {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return DisposalCategory.allCases
        }

        return DisposalCategory.allCases.filter { category in
            category.title.localizedCaseInsensitiveContains(trimmedText)
            || category.materialHint.localizedCaseInsensitiveContains(trimmedText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    header
                    searchField
                    categoryList
                    cautionCard
                }
                .padding(AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("배출가이드")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)

            Text("재질명이나 품목을 찾아 빠르게 확인해요.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.top, AppTheme.Spacing.lg)
    }

    private var searchField: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText)

            TextField("PET, 캔류, 비닐류", text: $searchText)
                .textInputAutocapitalization(.never)
                .font(.system(.body, design: .rounded))
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }

    private var categoryList: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(categories) { category in
                GuideCategoryCard(category: category)
            }
        }
    }

    private var cautionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                IconTile(systemName: "exclamationmark.triangle.fill", tint: AppTheme.warning, background: AppTheme.yellowSurface)
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("지역 기준이 다를 수 있어요")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("오염된 비닐, 코팅 종이컵, OTHER 표기는 지자체 기준을 함께 확인하세요.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .utilityCard()
    }
}

private struct GuideCategoryCard: View {
    let category: DisposalCategory

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                IconTile(systemName: category.symbolName, tint: category.tint)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(category.title)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    Text(category.materialHint)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(category.tint)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(category.guideSteps, id: \.self) { step in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "checkmark")
                            .font(.system(.caption, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 18, height: 18)

                        Text(step)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .utilityCard()
    }
}
