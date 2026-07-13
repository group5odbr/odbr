import SwiftUI

struct GuideView: View {
    @State private var searchText = ""

    private var categories: [DisposalCategory] {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return DisposalCategory.disposalCases
        }

        return DisposalCategory.disposalCases.filter { category in
            category.title.localizedCaseInsensitiveContains(trimmedText)
            || category.materialHint.localizedCaseInsensitiveContains(trimmedText)
            || category.searchKeywords.contains {
                $0.localizedCaseInsensitiveContains(trimmedText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    ScreenHeader(
                        title: "배출가이드",
                        subtitle: "재질명이나 품목을 찾아 빠르게 확인해요."
                    )
                    GuideSearchField(text: $searchText)
                    categoryList
                    cautionCard
                }
                .tabScreenPadding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .accessibilityIdentifier("guide.screen")
        }
    }

    private var categoryList: some View {
        Group {
            if categories.isEmpty {
                GuideEmptySearchCard(query: searchText)
            } else {
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(categories) { category in
                        GuideCategoryCard(category: category)
                    }
                }
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
                    Text("오염 비닐·코팅 종이컵·OTHER는 지역 안내를 확인하세요.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .utilityCard(warning: true)
    }
}

private struct GuideSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText)
                .accessibilityHidden(true)

            TextField("PET, 캔류, 비닐류", text: $text)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .font(.system(.body, design: .rounded))
                .accessibilityLabel("배출 품목 검색")

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .frame(minHeight: 52)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
        .accessibilityIdentifier("guide.search")
    }
}

private struct GuideEmptySearchCard: View {
    let query: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
                .accessibilityHidden(true)

            Text("검색 결과가 없어요")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)

            Text("‘\(query)’와 비슷한 재질명이나 품목명으로 검색해 보세요.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .utilityCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("guide.empty")
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
                            .accessibilityHidden(true)

                        Text(step)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .utilityCard()
        .accessibilityElement(children: .combine)
    }
}
