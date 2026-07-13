import SwiftUI

struct SearchView: View {
    @State private var store: ProductSearchStore
    @State private var searchText = ""
    let onShowInformation: () -> Void

    init(onShowInformation: @escaping () -> Void = {}) {
        _store = State(initialValue: ProductSearchStore())
        self.onShowInformation = onShowInformation
    }

    private var categories: [DisposalCategory] {
        let normalized = ProductSearchNormalizer.normalize(searchText)
        guard !normalized.isEmpty else { return DisposalCategory.disposalCases }
        return DisposalCategory.disposalCases.filter { category in
            let values = [category.title, category.materialHint] + category.searchKeywords
            return values.contains { ProductSearchNormalizer.normalize($0).contains(normalized) }
        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    ScreenHeader(
                        title: "분리배출 검색",
                        subtitle: "버릴 물건의 이름을 검색하고, 실제 모양과 가까운 것을 골라보세요.",
                        onShowInformation: onShowInformation
                    )

                    SearchField(text: $searchText)
                        .onChange(of: searchText) { _, value in
                            store.updateQuery(value)
                        }

                    if trimmedSearchText.isEmpty {
                        popularQueries
                    }

                    searchContent
                    cautionCard
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .tabScreenPadding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(for: ProductVariant.self) { variant in
                ProductVariantDetailView(variant: variant)
            }
            .accessibilityIdentifier("search.screen")
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        if trimmedSearchText.isEmpty {
            categoryList
        } else if !store.hits.isEmpty {
            productResults
        } else if !store.remoteVariants.isEmpty {
            remoteResults
        } else if !categories.isEmpty {
            categoryList
        } else {
            noResults
        }
    }

    private var popularQueries: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("헷갈리기 쉬운 품목")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(["영수증", "고무장갑", "보조배터리", "깨진 유리", "프라이팬", "부탄가스"], id: \.self) { query in
                        Button(query) {
                            searchText = query
                        }
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.deepGreen)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .frame(minHeight: 38)
                        .background(AppTheme.mintSurface)
                        .clipShape(Capsule())
                    }
                }
            }
            .accessibilityIdentifier("search.popular")
        }
    }

    private var productResults: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(store.hits.count == 1 ? "어떤 모양인가요?" : "비슷한 품목을 찾았어요")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)

            ForEach(store.hits) { hit in
                ProductFamilyResultCard(hit: hit)
            }

            if !categories.isEmpty {
                categoryList
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var remoteResults: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("가장 비슷한 모양을 골라주세요")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text(store.aiState == .cached ? "이전에 찾은 결과" : "AI 검색")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.deepGreen)
            }

            Text("이름만으로는 재질을 알기 어려워요. 실제 물건과 가장 비슷한 모양을 골라주세요.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(store.remoteVariants) { variant in
                NavigationLink(value: variant) {
                    ProductVariantChoiceCard(variant: variant)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("search.remoteResults")
    }

    private var noResults: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .accessibilityHidden(true)
                Text("‘\(trimmedSearchText)’ 검색 결과가 없어요")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text("아직 검색 결과가 없어요. AI로 한 번 더 찾아보거나 다른 이름·재질로 검색해 보세요.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .utilityCard()
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("search.empty")

            aiSearchButton
        }
    }

    private var aiSearchButton: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Button {
                store.requestAI()
            } label: {
                if store.aiState.isLoading {
                    ProgressView()
                        .tint(AppTheme.actionText)
                        .frame(maxWidth: .infinity)
                } else {
                    Label("AI로 다시 찾아보기", systemImage: "sparkles")
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(store.aiState.isLoading || ProductSearchNormalizer.normalize(trimmedSearchText).count < 2)
            .accessibilityIdentifier("search.ai")

            switch store.aiState {
            case .failed(let message):
                SearchErrorCard(message: message) {
                    store.requestAI()
                }
            case .unsupported:
                Text("AI로도 알맞은 품목을 찾지 못했어요. 물건의 다른 이름이나 재질을 검색해 보세요.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            case .loading:
                Text("AI가 비슷한 품목을 찾고 있어요. 잠시만 기다려 주세요.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            default:
                EmptyView()
            }
        }
    }

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("재질로 찾아보기")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
            ForEach(categories) { category in
                CategoryGuideCard(category: category)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cautionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                IconTile(systemName: "exclamationmark.triangle.fill", tint: AppTheme.warning, background: AppTheme.yellowSurface)
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("물건의 표시와 우리 동네 안내를 먼저 확인해요")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("같은 상품도 포장 모양이 다를 수 있어요. 오염됐거나 여러 재질이 섞였다면 우리 동네 안내를 확인하세요.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .utilityCard(warning: true)
    }
}

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText)
                .accessibilityHidden(true)

            TextField("영수증, 보조배터리, 깨진 유리", text: $text)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .font(.system(.body, design: .rounded))
                .accessibilityLabel("버릴 품목 검색")

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
        .frame(maxWidth: .infinity)
        .frame(minHeight: 52)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
        .accessibilityIdentifier("search.field")
    }
}

private struct ProductFamilyResultCard: View {
    let hit: ProductSearchHit

    private var orderedVariants: [ProductVariant] {
        let rank = Dictionary(uniqueKeysWithValues: hit.matchedVariantIDs.enumerated().map { ($1, $0) })
        return hit.family.variants.sorted { lhs, rhs in
            let lhsRank = rank[lhs.id] ?? Int.max
            let rhsRank = rank[rhs.id] ?? Int.max
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return (hit.family.variants.firstIndex(of: lhs) ?? 0) < (hit.family.variants.firstIndex(of: rhs) ?? 0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(hit.family.name)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("내가 버릴 물건과 가장 비슷한 모양을 고르세요")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Text("\(hit.family.variants.count)가지")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.deepGreen)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .frame(minHeight: 28)
                    .background(AppTheme.card.opacity(0.82))
                    .clipShape(Capsule())
            }

            ForEach(orderedVariants) { variant in
                NavigationLink(value: variant) {
                    ProductVariantChoiceCard(variant: variant)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .utilityCard(highlighted: true)
        .accessibilityIdentifier("search.family.\(hit.family.id)")
    }
}

private struct ProductVariantChoiceCard: View {
    let variant: ProductVariant

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            IconTile(systemName: variant.destination.symbolName, tint: variant.destination == .municipalCheck ? AppTheme.warning : AppTheme.accent)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(variant.title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(variant.selectionHint)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(variant.destination.title)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(variant.destination == .municipalCheck ? AppTheme.warning : AppTheme.deepGreen)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
                .accessibilityHidden(true)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("search.variant.\(variant.id)")
    }
}

private struct ProductVariantDetailView: View {
    let variant: ProductVariant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                ScreenHeader(title: variant.title, subtitle: variant.familyName)
                mainDestinationCard

                if !variant.parts.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        DetailSectionHeader(
                            title: "부분별로 나눠 보기",
                            subtitle: "본체와 붙어 있는 부분을 각각 확인해요."
                        )
                        ForEach(variant.parts) { part in
                            ProductPartGuideCard(part: part)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !variant.flags.isEmpty {
                    preparationCard
                }

                ForEach(variant.notes, id: \.self) { note in
                    Text(note)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .utilityCard()
                }

                officialGuideCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .tabScreenPadding()
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .accessibilityIdentifier("search.detail")
    }

    private var mainDestinationCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                IconTile(
                    systemName: variant.destination.symbolName,
                    tint: variant.destination == .municipalCheck ? AppTheme.warning : AppTheme.accent
                )
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("어디에 버리나요?")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(variant.destination.title)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }
                Spacer(minLength: 0)
            }

            Divider()
                .overlay(AppTheme.border)

            Text(variant.selectionHint)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .utilityCard(
            highlighted: variant.destination != .municipalCheck,
            warning: variant.destination == .municipalCheck
        )
    }

    private var preparationCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            DetailSectionHeader(
                title: "버리기 전에",
                subtitle: "아래 내용을 순서대로 확인해요."
            )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(variant.flags, id: \.self) { flag in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.deepGreen)
                            .accessibilityHidden(true)
                        Text(flag.text)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .utilityCard()
    }

    private var officialGuideCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                IconTile(systemName: "safari")
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("공식 분리배출 안내")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("지역별 기준과 예외 품목을 함께 확인할 수 있어요.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            Link(destination: URL(string: "https://www.wasteguide.or.kr/front/dischargeMethod/dictionary.do")!) {
                Label("공식 품목별 배출방법 확인", systemImage: "arrow.up.right")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("search.officialLink")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .utilityCard(highlighted: true)
    }
}

private struct DetailSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
            Text(subtitle)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProductPartGuideCard: View {
    let part: ProductPart

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            IconTile(systemName: part.destination.symbolName, tint: part.destination == .municipalCheck ? AppTheme.warning : AppTheme.accent)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(part.name)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(part.destination.title)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(part.destination == .municipalCheck ? AppTheme.warning : AppTheme.deepGreen)
                Text(part.separation.title)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                if let note = part.note {
                    Text(note)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .utilityCard()
        .accessibilityElement(children: .combine)
    }
}

private struct SearchErrorCard: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(message)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button("다시 시도", action: retry)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.deepGreen)
                .accessibilityIdentifier("search.aiRetry")
        }
        .utilityCard(warning: true)
    }
}

private struct CategoryGuideCard: View {
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
                    Label(step, systemImage: "checkmark")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
        }
        .utilityCard()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SearchView()
}
