import SwiftUI

struct SearchView: View {
    @State private var store: ProductSearchStore
    @State private var searchText = ""

    init() {
        _store = State(initialValue: ProductSearchStore())
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
                        subtitle: "상품명이나 브랜드명을 찾고, 실제 포장 형태를 골라 확인해요."
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
            Text("자주 찾는 검색어")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(["콜라", "소주병", "인형", "컵라면", "화장품", "보조배터리"], id: \.self) { query in
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
            if !categories.isEmpty {
                categoryList
            }

            Text(store.hits.count == 1 ? "어떤 형태인가요?" : "비슷한 상품군을 찾았어요")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)

            ForEach(store.hits) { hit in
                ProductFamilyResultCard(hit: hit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var remoteResults: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("상품 형태 선택")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text(store.aiState == .cached ? "저장된 결과" : "AI 보강")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.deepGreen)
            }

            Text("검색어만으로 재질을 확정하지 않고, 실제 물건과 가까운 형태를 골라요.")
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
                Text("상품 유형을 AI로 찾아 선택지를 만들거나, PET·캔류처럼 재질명을 검색해 보세요.")
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
                    Label("AI로 상품 형태 찾기", systemImage: "sparkles")
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
                Text("안전하게 연결할 수 있는 상품 유형이 없어요. 실제 분리배출 표기나 재질명을 확인해 주세요.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            case .loading:
                Text("상품 형태를 확인하는 중이에요. 잠시만 기다려 주세요.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            default:
                EmptyView()
            }
        }
    }

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("재질별 기본 가이드")
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
                    Text("실물 표기와 지역 기준을 우선해요")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("같은 상품도 포장 형태가 다를 수 있어요. 오염·복합재질·OTHER는 지자체 안내를 확인하세요.")
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

            TextField("콜라, 소주병, 인형, PET", text: $text)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .font(.system(.body, design: .rounded))
                .accessibilityLabel("상품·브랜드 검색")

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

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(hit.family.name)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("실제 포장과 가장 가까운 형태를 선택하세요")
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

            ForEach(hit.family.variants) { variant in
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
                            title: "부위별로 나눠 보기",
                            subtitle: "본체와 부착물을 각각 확인해요."
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
                        .utilityCard(warning: variant.origin == .aiGenerated)
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
                    Text("주 배출 경로")
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

            if variant.origin == .aiGenerated {
                Label(
                    "AI가 제안한 유형이에요. 실제 분리배출 표기와 재질을 반드시 확인하세요.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.warning)
                .fixedSize(horizontal: false, vertical: true)
            }
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
                title: "배출 전 처리",
                subtitle: "배출 전에 순서대로 확인해요."
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

typealias GuideView = SearchView

#Preview {
    SearchView()
}
