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

typealias DisposalDestination = DisposalRoute

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
    case doNotDisassemble
    case insulateTerminals
    case wrapSharpEdges
    case sealAndLabelHazard

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
            "우리 동네에서 받는 품목과 장소를 확인해요."
        case .donateIfUsable:
            "재사용할 수 있으면 기부·나눔을 먼저 고려해요."
        case .removeResidue:
            "음식물과 이물질을 최대한 제거해요."
        case .doNotDisassemble:
            "사용자가 쉽게 분리할 수 없는 내장 배터리는 임의로 분해하지 마세요."
        case .insulateTerminals:
            "노출된 배터리 단자는 절연 테이프로 감싸요."
        case .wrapSharpEdges:
            "깨지거나 날카로운 부분은 신문지 등으로 감싸고 위험 표시를 해요."
        case .sealAndLabelHazard:
            "잔류물이 새지 않도록 밀봉하고 위험성을 표시해요."
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

    var title: String {
        switch self {
        case .localCatalog:
            "앱에 저장된 안내"
        case .aiCatalogMatch:
            "AI가 찾은 안내"
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
    let confidence: Int
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
            "AI 검색 결과를 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
        case .unsupported:
            "AI로 알맞은 품목을 찾지 못했어요. 다른 이름이나 재질을 검색해 보세요."
        }
    }
}
