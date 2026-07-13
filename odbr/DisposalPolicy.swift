import Foundation

nonisolated enum RecyclingStream: String, Codable, CaseIterable, Identifiable, Sendable {
    case clearPETBottle
    case plasticContainerTray
    case vinylPackaging
    case paper
    case paperPack
    case metalCan
    case glassBottle
    case foamPackaging
    case metalScrap

    var id: String { rawValue }
}

nonisolated enum DisposalRoute: Hashable, Codable, Identifiable, Sendable {
    case recyclable(RecyclingStream)
    case volumeRateBag
    case specialWasteBag
    case foodWaste
    case largeWaste
    case batteryCollection
    case electronicsCollection
    case lightingCollection
    case clothingCollection
    case householdHazardousWaste
    case depositReturn
    case operatorCollection
    case municipalCheck
    case unknown

    private enum CodingKeys: String, CodingKey {
        case type
        case stream
    }

    private enum RouteType: String, Codable {
        case recyclable
        case volumeRateBag
        case specialWasteBag
        case foodWaste
        case largeWaste
        case batteryCollection
        case electronicsCollection
        case lightingCollection
        case clothingCollection
        case householdHazardousWaste
        case depositReturn
        case operatorCollection
        case municipalCheck
        case unknown
    }

    var id: String {
        switch self {
        case let .recyclable(stream):
            return "recyclable.\(stream.rawValue)"
        default:
            return routeType.rawValue
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(RouteType.self, forKey: .type) {
        case .recyclable:
            self = .recyclable(try container.decode(RecyclingStream.self, forKey: .stream))
        case .volumeRateBag: self = .volumeRateBag
        case .specialWasteBag: self = .specialWasteBag
        case .foodWaste: self = .foodWaste
        case .largeWaste: self = .largeWaste
        case .batteryCollection: self = .batteryCollection
        case .electronicsCollection: self = .electronicsCollection
        case .lightingCollection: self = .lightingCollection
        case .clothingCollection: self = .clothingCollection
        case .householdHazardousWaste: self = .householdHazardousWaste
        case .depositReturn: self = .depositReturn
        case .operatorCollection: self = .operatorCollection
        case .municipalCheck: self = .municipalCheck
        case .unknown: self = .unknown
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(routeType, forKey: .type)
        if case let .recyclable(stream) = self {
            try container.encode(stream, forKey: .stream)
        }
    }

    private var routeType: RouteType {
        switch self {
        case .recyclable: .recyclable
        case .volumeRateBag: .volumeRateBag
        case .specialWasteBag: .specialWasteBag
        case .foodWaste: .foodWaste
        case .largeWaste: .largeWaste
        case .batteryCollection: .batteryCollection
        case .electronicsCollection: .electronicsCollection
        case .lightingCollection: .lightingCollection
        case .clothingCollection: .clothingCollection
        case .householdHazardousWaste: .householdHazardousWaste
        case .depositReturn: .depositReturn
        case .operatorCollection: .operatorCollection
        case .municipalCheck: .municipalCheck
        case .unknown: .unknown
        }
    }

    static let selectableCases: [DisposalRoute] =
        RecyclingStream.allCases.map(DisposalRoute.recyclable) + [
            .volumeRateBag,
            .specialWasteBag,
            .foodWaste,
            .largeWaste,
            .batteryCollection,
            .electronicsCollection,
            .lightingCollection,
            .clothingCollection,
            .householdHazardousWaste,
            .depositReturn,
            .operatorCollection,
            .municipalCheck
        ]

    static func category(_ category: DisposalCategory) -> DisposalRoute {
        switch category {
        case .pet: .recyclable(.clearPETBottle)
        case .plastic: .recyclable(.plasticContainerTray)
        case .vinyl: .recyclable(.vinylPackaging)
        case .paper: .recyclable(.paper)
        case .paperPack: .recyclable(.paperPack)
        case .can: .recyclable(.metalCan)
        case .glass: .recyclable(.glassBottle)
        case .styrofoam: .recyclable(.foamPackaging)
        case .general: .volumeRateBag
        case .unknown: .unknown
        }
    }

    static var smallElectronicsCollection: DisposalRoute { .electronicsCollection }

    var legacyCategory: DisposalCategory {
        switch self {
        case .recyclable(.clearPETBottle): .pet
        case .recyclable(.plasticContainerTray): .plastic
        case .recyclable(.vinylPackaging): .vinyl
        case .recyclable(.paper): .paper
        case .recyclable(.paperPack): .paperPack
        case .recyclable(.metalCan): .can
        case .recyclable(.glassBottle): .glass
        case .recyclable(.foamPackaging): .styrofoam
        case .volumeRateBag: .general
        case .recyclable(.metalScrap), .specialWasteBag, .foodWaste, .largeWaste,
             .batteryCollection, .electronicsCollection, .lightingCollection,
             .clothingCollection, .householdHazardousWaste, .depositReturn,
             .operatorCollection, .municipalCheck, .unknown:
            .unknown
        }
    }

    var title: String {
        switch self {
        case .recyclable(.clearPETBottle): "투명 음료 페트병"
        case .recyclable(.plasticContainerTray): "플라스틱 용기·트레이"
        case .recyclable(.vinylPackaging): "비닐류"
        case .recyclable(.paper): "종이류"
        case .recyclable(.paperPack): "종이팩류"
        case .recyclable(.metalCan): "음료·식품 캔류"
        case .recyclable(.glassBottle): "유리병류"
        case .recyclable(.foamPackaging): "스티로폼 포장재"
        case .recyclable(.metalScrap): "고철·금속류"
        case .volumeRateBag: "일반쓰레기"
        case .specialWasteBag: "깨진 유리·도자기"
        case .foodWaste: "음식물쓰레기"
        case .largeWaste: "대형폐기물"
        case .batteryCollection: "폐건전지·전지 수거함"
        case .electronicsCollection: "소형가전 수거함"
        case .lightingCollection: "형광등·전구 수거함"
        case .clothingCollection: "의류수거함"
        case .householdHazardousWaste: "위험한 생활폐기물"
        case .depositReturn: "보증금 병 반환"
        case .operatorCollection: "전용 회수기"
        case .municipalCheck: "우리 동네 기준 확인"
        case .unknown: "확인하기 어려워요"
        }
    }

    var detail: String {
        DisposalPolicyCatalog.policy(for: self).summary
    }

    var symbolName: String {
        switch self {
        case .recyclable(.clearPETBottle): "drop.fill"
        case .recyclable(.plasticContainerTray): "shippingbox.fill"
        case .recyclable(.vinylPackaging): "bag.fill"
        case .recyclable(.paper): "doc.text.fill"
        case .recyclable(.paperPack): "takeoutbag.and.cup.and.straw.fill"
        case .recyclable(.metalCan): "cylinder.fill"
        case .recyclable(.glassBottle): "drop.triangle.fill"
        case .recyclable(.foamPackaging): "shippingbox.and.arrow.backward.fill"
        case .recyclable(.metalScrap): "wrench.and.screwdriver.fill"
        case .volumeRateBag: "trash.fill"
        case .specialWasteBag: "bag.badge.plus"
        case .foodWaste: "leaf.fill"
        case .largeWaste: "sofa.fill"
        case .batteryCollection: "battery.100percent"
        case .electronicsCollection: "desktopcomputer"
        case .lightingCollection: "lightbulb.fill"
        case .clothingCollection: "tshirt.fill"
        case .householdHazardousWaste: "exclamationmark.shield.fill"
        case .depositReturn: "arrow.uturn.backward.circle.fill"
        case .operatorCollection: "building.2.fill"
        case .municipalCheck: "building.columns.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }
}

nonisolated enum DisposalHazard: String, Codable, CaseIterable, Sendable {
    case pressurizedContainer
    case flammableResidue
    case chemicalResidue
    case brokenGlass
    case sharpObject
    case damagedBattery
}

nonisolated enum NephronEligibility: String, Codable, Sendable {
    case likelyEligible
    case checkMachine
    case notEligible
    case unknown
}

nonisolated struct DisposalPolicy: Codable, Hashable, Sendable {
    let route: DisposalRoute
    let summary: String
    let preparationSteps: [String]
    let warnings: [String]
    let sourceID: String
    let effectiveDate: String
    let reviewedAt: String
    let localVariationRequired: Bool
    let nephronEligibility: NephronEligibility
}

nonisolated enum DisposalPolicyCatalog {
    static let version = 2
    static let sourceURL = URL(string: "https://www.wasteguide.or.kr/front/dischargeMethod/typeItemHtml.do")!
    static let reviewedAt = "2026-07-14"

    static let policies: [DisposalPolicy] = loadPolicies()

    static func policy(for route: DisposalRoute) -> DisposalPolicy {
        policies.first { $0.route == route } ?? fallbackPolicy(for: route)
    }

    private static func loadPolicies() -> [DisposalPolicy] {
        guard
            let url = Bundle.main.url(forResource: "DisposalPolicies", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([DisposalPolicy].self, from: data),
            Set(decoded.map(\.route)).count == decoded.count
        else {
            return DisposalRoute.selectableCases.map(fallbackPolicy) + [fallbackPolicy(for: .unknown)]
        }
        return decoded
    }

    private static func fallbackPolicy(for route: DisposalRoute) -> DisposalPolicy {
        let values: (String, [String], [String], Bool, NephronEligibility)
        switch route {
        case .recyclable(.clearPETBottle):
            values = (
                "색이 없는 투명 생수병과 음료병만 해당해요.",
                ["내용물을 비우고 필요한 경우 헹궈요.", "라벨을 제거해 비닐류로 분리해요.", "가능하면 압착한 뒤 뚜껑을 닫아 배출해요."],
                ["병에 PET라고 적혀 있어도 색과 용도를 함께 확인해야 해요."],
                true,
                .likelyEligible
            )
        case .recyclable(.plasticContainerTray):
            values = ("색이 있는 페트병과 플라스틱 용기·트레이예요.", ["내용물과 이물질을 제거해요.", "다른 재질은 가능한 만큼 떼어내요."], [], true, .notEligible)
        case .recyclable(.vinylPackaging):
            values = ("비닐 포장재와 일회용 비닐봉투가 대상이에요.", ["내용물과 이물질을 제거해요.", "흩날리지 않도록 모아서 배출해요."], ["고무장갑·식탁보·장판·오염을 제거할 수 없는 랩은 비닐류가 아니에요."], true, .notEligible)
        case .recyclable(.paper):
            values = ("물기·기름기·코팅이 없는 종이류예요.", ["택배송장·테이프·금속 부착물을 제거해요.", "상자는 펼쳐서 배출해요."], ["영수증 감열지와 사용한 휴지·키친타월은 종이류가 아니에요."], true, .notEligible)
        case .recyclable(.paperPack):
            values = ("우유팩·주스팩·멸균팩 같은 액체용 종이팩이에요.", ["내용물을 비우고 헹궈요.", "펼쳐서 말린 뒤 종이팩류로 배출해요."], [], true, .notEligible)
        case .recyclable(.metalCan):
            values = ("음료캔과 내용물을 비운 식품캔이 대상이에요.", ["내용물을 비우고 이물질을 제거해요."], ["가스나 위험한 내용물이 남은 용기는 따로 확인하세요."], true, .checkMachine)
        case .recyclable(.glassBottle):
            values = ("음료·식품 유리병이 대상이에요.", ["내용물을 비우고 필요한 경우 헹궈요."], ["유리컵·내열유리·거울·도자기·깨진 유리는 유리병류가 아니에요."], true, .notEligible)
        case .recyclable(.foamPackaging):
            values = ("깨끗한 스티로폼 포장재가 대상이에요.", ["테이프와 운송장을 제거해요.", "음식물과 이물질을 제거해요."], ["다른 재질이 붙었거나 건축용·오염된 제품은 우리 동네 배출 방법을 확인하세요."], true, .notEligible)
        case .recyclable(.metalScrap):
            values = ("프라이팬·냄비·공구 같은 고철·금속류를 버리는 방법이에요.", ["내용물과 이물질을 제거해요.", "분리 가능한 손잡이 등 다른 재질을 분리해요."], ["크기와 섞인 재질에 따라 우리 동네 배출 방법이 달라질 수 있어요."], true, .notEligible)
        case .volumeRateBag:
            values = ("재활용하기 어려운 생활폐기물은 일반쓰레기로 버려요.", ["재활용 가능한 부분은 먼저 분리하고 일반쓰레기 봉투에 담아요."], [], true, .notEligible)
        case .specialWasteBag:
            values = ("깨진 유리·도자기처럼 날카로운 물건을 안전하게 버리는 방법이에요.", ["날카로운 부분을 신문지 등으로 감싸고 위험 표시를 해요."], ["지역에 따라 일반쓰레기 봉투·불연성 봉투·대형폐기물 등 배출 방법이 달라요."], true, .notEligible)
        case .foodWaste:
            values = ("지역에서 음식물류 폐기물로 받는 품목인지 확인해요.", ["물기와 이물질을 제거해요."], ["뼈·큰 씨·티백 등은 지역 기준에 따라 제외될 수 있어요."], true, .notEligible)
        case .largeWaste:
            values = ("일반쓰레기 봉투에 담기 어려운 큰 물건이에요.", ["우리 동네의 신고·스티커·예약 수거 방법을 확인해요."], [], true, .notEligible)
        case .batteryCollection:
            values = ("폐건전지와 쉽게 분리할 수 있는 전지는 전용 수거함에 넣어요.", ["노출된 단자는 절연 테이프로 감싸요."], ["부풀거나 깨졌거나 뜨거우면 일반 수거함에 넣지 말고 우리 동네 안전 안내를 확인하세요."], true, .notEligible)
        case .electronicsCollection:
            values = ("전지 내장형 제품과 소형 전자제품을 제품 그대로 전용 수거함에 배출해요.", ["쉽게 분리되는 전지만 분리해요."], ["내장 배터리를 임의로 분해하지 마세요."], true, .notEligible)
        case .lightingCollection:
            values = ("깨지지 않은 형광등과 LED 조명을 전용 수거함에 배출해요.", ["깨지지 않도록 포장해 이동해요."], ["깨진 조명은 정상 조명 수거함에 넣지 말고 지역별 안전 경로를 확인하세요."], true, .notEligible)
        case .clothingCollection:
            values = ("깨끗하고 재사용 가능한 의류·원단을 의류수거함에 배출해요.", ["물기와 오염을 제거해요."], [], true, .notEligible)
        case .householdHazardousWaste:
            values = ("가스·페인트·약품 등이 남은 위험한 생활폐기물이에요.", ["내용물이 새지 않도록 밀봉하고 위험하다는 표시를 해요."], ["다른 내용물과 섞거나 일반 재활용함에 넣지 마세요."], true, .notEligible)
        case .depositReturn:
            values = ("빈용기보증금 표시가 있는 병을 소매점 등 반환처에 반납해요.", ["내용물을 비워요."], [], false, .notEligible)
        case .operatorCollection:
            values = ("회수기마다 받는 품목과 상태가 달라요.", ["방문 전에 운영 여부와 넣을 수 있는 병·캔을 확인해요."], [], true, .checkMachine)
        case .municipalCheck:
            values = ("물건의 크기와 재질에 따라 버리는 방법이 달라요.", ["공식 분리배출 안내와 우리 동네 방법을 확인해요."], [], true, .notEligible)
        case .unknown:
            values = ("사진만으로 버리는 방법을 확실히 알기 어려워요.", ["물건 하나와 분리배출 표시가 잘 보이게 다시 찍어요.", "품목 검색에서 가장 비슷한 물건을 골라 확인해요."], [], true, .unknown)
        }

        return DisposalPolicy(
            route: route,
            summary: values.0,
            preparationSteps: values.1,
            warnings: values.2,
            sourceID: "wasteguide-national-2026",
            effectiveDate: "2026-01-01",
            reviewedAt: reviewedAt,
            localVariationRequired: values.3,
            nephronEligibility: values.4
        )
    }
}

nonisolated enum CorrectionCandidateReason: String, Sendable {
    case modelAlternative
    case ocrConflict
    case materialAlternative
    case shapeAlternative
    case policyFallback

    var title: String {
        switch self {
        case .modelAlternative: "AI가 찾은 다음 후보"
        case .ocrConflict: "표시와 사진이 달랐던 후보"
        case .materialAlternative: "비슷한 재질 후보"
        case .shapeAlternative: "비슷한 형태 후보"
        case .policyFallback: "목록에서 직접 선택"
        }
    }
}

nonisolated struct CorrectionCandidate: Identifiable, Sendable {
    let route: DisposalRoute
    let reason: CorrectionCandidateReason

    var id: String { route.id }
}

nonisolated enum CorrectionCandidateBuilder {
    static func ranked(for result: DisposalResult) -> [CorrectionCandidate] {
        var seen = Set([result.route, DisposalRoute.unknown])
        return result.candidates
            .map(DisposalRoute.category)
            .filter { seen.insert($0).inserted }
            .prefix(3)
            .map { CorrectionCandidate(route: $0, reason: .modelAlternative) }
    }

    static func allRoutes(excluding result: DisposalResult) -> [DisposalRoute] {
        let ranked = Set(ranked(for: result).map(\.route))
        return DisposalRoute.selectableCases.filter { $0 != result.route && !ranked.contains($0) }
    }
}
