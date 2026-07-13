import Foundation

nonisolated enum ProductFamilyKind: String, Codable, CaseIterable, Sendable {
    case cola
    case beverage
    case water
    case paperPackBeverage
    case alcohol
    case foodPackage
    case paperFoodPackage
    case plasticContainer
    case vinylPackage
    case householdBottle
    case cosmetics
    case hygiene
    case paperProduct
    case deliveryPackage
    case foamPackage
    case icePack
    case doll
    case toy
    case battery
    case electronics
    case lighting
    case textile
    case generalItem
}

nonisolated enum DisposalDestination: Codable, Hashable, Sendable {
    case category(DisposalCategory)
    case batteryCollection
    case smallElectronicsCollection
    case lightingCollection
    case clothingCollection
    case largeWaste
    case municipalCheck

    private enum CodingKeys: String, CodingKey {
        case type
        case category
    }

    private enum DestinationType: String, Codable {
        case category
        case batteryCollection
        case smallElectronicsCollection
        case lightingCollection
        case clothingCollection
        case largeWaste
        case municipalCheck
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(DestinationType.self, forKey: .type)
        switch type {
        case .category:
            self = .category(try container.decode(DisposalCategory.self, forKey: .category))
        case .batteryCollection:
            self = .batteryCollection
        case .smallElectronicsCollection:
            self = .smallElectronicsCollection
        case .lightingCollection:
            self = .lightingCollection
        case .clothingCollection:
            self = .clothingCollection
        case .largeWaste:
            self = .largeWaste
        case .municipalCheck:
            self = .municipalCheck
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .category(category):
            try container.encode(DestinationType.category, forKey: .type)
            try container.encode(category, forKey: .category)
        case .batteryCollection:
            try container.encode(DestinationType.batteryCollection, forKey: .type)
        case .smallElectronicsCollection:
            try container.encode(DestinationType.smallElectronicsCollection, forKey: .type)
        case .lightingCollection:
            try container.encode(DestinationType.lightingCollection, forKey: .type)
        case .clothingCollection:
            try container.encode(DestinationType.clothingCollection, forKey: .type)
        case .largeWaste:
            try container.encode(DestinationType.largeWaste, forKey: .type)
        case .municipalCheck:
            try container.encode(DestinationType.municipalCheck, forKey: .type)
        }
    }

    var title: String {
        switch self {
        case let .category(category):
            category.title
        case .batteryCollection:
            "전지류 수거함"
        case .smallElectronicsCollection:
            "소형 전자제품 전용수거"
        case .lightingCollection:
            "조명제품 수거함"
        case .clothingCollection:
            "의류수거함"
        case .largeWaste:
            "대형폐기물"
        case .municipalCheck:
            "지자체 기준 확인"
        }
    }

    var detail: String {
        switch self {
        case let .category(category):
            category.materialHint
        case .batteryCollection:
            "전용 수거함이나 지정된 배출 장소"
        case .smallElectronicsCollection:
            "소형 전기·전자제품 전용수거함"
        case .lightingCollection:
            "깨지지 않도록 전용 수거함에 배출"
        case .clothingCollection:
            "오염되지 않은 의류·원단 전용수거함"
        case .largeWaste:
            "지역 신고·스티커 등 지자체 방법 확인"
        case .municipalCheck:
            "지역별 수거 품목과 배출 장소가 다를 수 있음"
        }
    }

    var symbolName: String {
        switch self {
        case let .category(category):
            switch category {
            case .pet: "drop.fill"
            case .plastic: "shippingbox.fill"
            case .vinyl: "bag.fill"
            case .paper: "doc.text.fill"
            case .paperPack: "takeoutbag.and.cup.and.straw.fill"
            case .can: "circle.fill"
            case .glass: "drop.triangle.fill"
            case .styrofoam: "shippingbox.and.arrow.backward.fill"
            case .general: "trash.fill"
            case .unknown: "questionmark.circle.fill"
            }
        case .batteryCollection:
            "battery.100percent"
        case .smallElectronicsCollection:
            "desktopcomputer"
        case .lightingCollection:
            "lightbulb.fill"
        case .clothingCollection:
            "tshirt.fill"
        case .largeWaste:
            "shippingbox.fill"
        case .municipalCheck:
            "questionmark.circle.fill"
        }
    }
}

nonisolated enum PartSeparationPolicy: String, Codable, CaseIterable, Sendable {
    case mainBody
    case remove
    case keepAttached
    case separateIfPossible
    case dedicatedCollection

    var title: String {
        switch self {
        case .mainBody:
            "본체"
        case .remove:
            "분리해서 배출"
        case .keepAttached:
            "닫아서 함께 배출"
        case .separateIfPossible:
            "분리 가능하면 따로 배출"
        case .dedicatedCollection:
            "전용 수거함 이용"
        }
    }
}

nonisolated enum ProductHandlingFlag: String, Codable, CaseIterable, Sendable {
    case emptyAndRinse
    case removeLabel
    case compressAndClose
    case returnDepositBottle
    case removeBattery
    case checkSize
    case checkMunicipality
    case donateIfUsable
    case removeResidue

    var text: String {
        switch self {
        case .emptyAndRinse:
            "내용물을 비우고 물로 헹궈요."
        case .removeLabel:
            "라벨·스티커는 가능한 범위에서 제거해요."
        case .compressAndClose:
            "가능하면 압착하고 뚜껑을 닫아 배출해요."
        case .returnDepositBottle:
            "빈용기보증금 대상이면 소매점 반납을 먼저 확인해요."
        case .removeBattery:
            "분리 가능한 전지는 제품에서 빼서 전지수거함에 배출해요."
        case .checkSize:
            "크기가 크면 대형폐기물 신고 대상인지 확인해요."
        case .checkMunicipality:
            "지역별 수거 품목·장소를 확인해요."
        case .donateIfUsable:
            "재사용할 수 있으면 기부·나눔을 먼저 고려해요."
        case .removeResidue:
            "음식물과 이물질을 최대한 제거해요."
        }
    }
}

nonisolated struct ProductPart: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let destination: DisposalDestination
    let separation: PartSeparationPolicy
    let note: String?

    init(
        id: String,
        name: String,
        destination: DisposalDestination,
        separation: PartSeparationPolicy,
        note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.destination = destination
        self.separation = separation
        self.note = note
    }
}

nonisolated enum ProductSearchOrigin: String, Codable, Sendable {
    case localCatalog
    case aiCatalogMatch
    case aiGenerated

    var title: String {
        switch self {
        case .localCatalog:
            "오프라인 카탈로그"
        case .aiCatalogMatch:
            "상품군 보강"
        case .aiGenerated:
            "AI 유형 제안"
        }
    }
}

nonisolated struct ProductVariant: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let familyName: String
    let title: String
    let aliases: [String]
    let selectionHint: String
    let destination: DisposalDestination
    let parts: [ProductPart]
    let flags: [ProductHandlingFlag]
    let notes: [String]
    let origin: ProductSearchOrigin

    init(
        id: String,
        familyName: String,
        title: String,
        aliases: [String] = [],
        selectionHint: String,
        destination: DisposalDestination,
        parts: [ProductPart] = [],
        flags: [ProductHandlingFlag] = [],
        notes: [String] = [],
        origin: ProductSearchOrigin = .localCatalog
    ) {
        self.id = id
        self.familyName = familyName
        self.title = title
        self.aliases = aliases
        self.selectionHint = selectionHint
        self.destination = destination
        self.parts = parts
        self.flags = flags
        self.notes = notes
        self.origin = origin
    }
}

nonisolated struct ProductFamily: Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let aliases: [String]
    let kind: ProductFamilyKind
    let priority: Int

    var variants: [ProductVariant] {
        ProductVariantFactory.variants(for: self)
    }
}

nonisolated struct ProductSearchHit: Hashable, Identifiable, Sendable {
    let family: ProductFamily
    let score: Int
    let matchedVariantIDs: [String]

    var id: String { family.id }
}

nonisolated enum ProductSearchAIState: Equatable, Sendable {
    case idle
    case loading
    case loaded(origin: ProductSearchOrigin)
    case cached
    case unsupported
    case failed(String)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}

nonisolated struct ProductSearchAIResponse: Codable, Sendable {
    let resolution: String
    let catalogFamilyID: String
    let familyName: String
    let confidence: Int
    let variants: [Variant]

    struct Variant: Codable, Sendable {
        let title: String
        let selectionHint: String
        let parts: [Part]
    }

    struct Part: Codable, Sendable {
        let name: String
        let route: String
        let separation: String
    }
}

nonisolated enum ProductSearchError: Error, Equatable, Sendable {
    case firebaseUnavailable(String)
    case invalidResponse
    case unsupported
    case server(String)

    var message: String {
        switch self {
        case let .firebaseUnavailable(message), let .server(message):
            message
        case .invalidResponse:
            "상품 유형 응답을 안전하게 해석하지 못했어요. 잠시 후 다시 시도해 주세요."
        case .unsupported:
            "현재 지원하는 배출 경로로 연결할 수 있는 상품 유형을 찾지 못했어요. 재질명이나 분리배출 표기를 검색해 보세요."
        }
    }
}
