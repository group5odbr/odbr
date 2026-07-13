import Foundation

nonisolated enum RecognitionSource: Equatable, Sendable {
    case mark
    case combined
    case multimodalAI
    case localFallback
    case userCorrection

    var title: String {
        switch self {
        case .mark:
            "분리배출 마크 확인"
        case .combined:
            "사진과 마크 함께 확인"
        case .multimodalAI:
            "AI 사진 확인"
        case .localFallback:
            "기본 안전 안내"
        case .userCorrection:
            "직접 고른 결과"
        }
    }
}

nonisolated enum DisposalCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case pet
    case plastic
    case vinyl
    case paper
    case paperPack
    case can
    case glass
    case styrofoam
    case general
    case unknown

    var id: String { rawValue }

    static var disposalCases: [DisposalCategory] {
        allCases.filter { $0 != .unknown }
    }

    var title: String {
        switch self {
        case .pet:
            "투명 음료 페트병"
        case .plastic:
            "플라스틱류"
        case .vinyl:
            "비닐류"
        case .paper:
            "종이류"
        case .paperPack:
            "종이팩류"
        case .can:
            "음료·식품 캔류"
        case .glass:
            "유리병류"
        case .styrofoam:
            "스티로폼 포장재"
        case .general:
            "일반쓰레기"
        case .unknown:
            "판단 보류"
        }
    }

    var materialHint: String {
        switch self {
        case .pet:
            "색이 없는 투명 생수병·음료병"
        case .plastic:
            "단단한 플라스틱 용기와 트레이"
        case .vinyl:
            "비닐봉투와 포장 비닐"
        case .paper:
            "신문·책·상자·종이봉투"
        case .paperPack:
            "우유팩·주스팩·두유팩"
        case .can:
            "음료캔과 통조림캔"
        case .glass:
            "음료·식품 유리병"
        case .styrofoam:
            "포장·완충용 스티로폼"
        case .general:
            "영수증·휴지·오염된 포장처럼 재활용하기 어려운 물건"
        case .unknown:
            "물건과 분리배출 표시를 더 가까이 찍어주세요"
        }
    }

    var searchKeywords: [String] {
        switch self {
        case .pet:
            ["생수병", "음료병", "투명 페트병", "무색 페트병"]
        case .plastic:
            ["배달 용기", "요거트 용기", "플라스틱 컵", "병뚜껑", "커피 캡슐"]
        case .vinyl:
            ["과자 봉지", "라면 봉지", "비닐 봉투", "랩", "파우치"]
        case .paper:
            ["신문", "책", "상자", "택배 박스", "종이 봉투"]
        case .paperPack:
            ["우유팩", "주스팩", "두유팩", "멸균팩"]
        case .can:
            ["음료 캔", "통조림", "철캔", "알루미늄캔", "커피 캡슐"]
        case .glass:
            ["소주병", "맥주병", "잼병", "유리 용기"]
        case .styrofoam:
            ["스티로폼 상자", "완충재", "발포 상자", "EPS"]
        case .general:
            ["영수증", "마스크", "기저귀", "휴지", "고무장갑", "배변패드", "도자기", "유리컵", "인형", "장난감"]
        case .unknown:
            []
        }
    }

    var guideSteps: [String] {
        DisposalPolicyCatalog.policy(for: .category(self)).preparationSteps
    }

    var canUseNephron: Bool {
        let eligibility = DisposalPolicyCatalog.policy(for: .category(self)).nephronEligibility
        return eligibility == .likelyEligible || eligibility == .checkMachine
    }
}

nonisolated struct DisposalEvidence: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let detail: String
}

nonisolated struct RecognitionSignal: Sendable {
    let category: DisposalCategory
    let confidence: Int
    let evidence: DisposalEvidence
    let candidates: [DisposalCategory]
}

nonisolated struct OCRInspection: Sendable {
    let textLines: [String]
    let signal: RecognitionSignal?
    let failureReason: String?

    init(
        textLines: [String],
        signal: RecognitionSignal?,
        failureReason: String? = nil
    ) {
        self.textLines = textLines
        self.signal = signal
        self.failureReason = failureReason
    }
}

nonisolated struct AIModelInspection: Sendable {
    let status: String
    let detail: String
}

nonisolated enum MultimodalEvidenceBasis: String, Codable, CaseIterable, Sendable {
    case explicitMark
    case materialAndShape
    case materialOnly
    case shapeOnly
    case nonRecyclableItem
    case contamination
    case composite
    case safetyHazard
    case conflicting
    case insufficient
}

nonisolated enum CaptureIssue: String, Codable, CaseIterable, Sendable {
    case none
    case multipleObjects
    case blurred
    case tooFar
    case markUnreadable
    case cropped

    var guidance: String {
        switch self {
        case .none:
            "물체와 분리배출 표기가 함께 보이게 촬영해 주세요."
        case .multipleObjects:
            "한 번에 쓰레기 하나만 화면 중앙에 놓아 주세요."
        case .blurred:
            "카메라를 고정하고 초점을 맞춘 뒤 다시 촬영해 주세요."
        case .tooFar:
            "재질과 표기가 읽히도록 물체에 더 가까이 다가가 주세요."
        case .markUnreadable:
            "분리배출 표기가 정면으로 선명하게 보이게 촬영해 주세요."
        case .cropped:
            "물체 전체와 표기가 프레임 안에 들어오게 촬영해 주세요."
        }
    }
}

nonisolated struct DisposalPartDecision: Codable, Equatable, Sendable {
    let component: String
    let category: DisposalCategory
}

nonisolated struct MultimodalDisposalDecision: Codable, Equatable, Sendable {
    let route: DisposalRoute
    let objectName: String
    let confidence: Int
    let basis: MultimodalEvidenceBasis
    let visibleMark: String
    let alternatives: [DisposalCategory]
    let captureIssue: CaptureIssue
    let parts: [DisposalPartDecision]
    let hazards: [DisposalHazard]
    let nephronEligibility: NephronEligibility

    var category: DisposalCategory { route.legacyCategory }

    init(
        category: DisposalCategory,
        objectName: String,
        confidence: Int,
        basis: MultimodalEvidenceBasis,
        visibleMark: String,
        alternatives: [DisposalCategory],
        captureIssue: CaptureIssue,
        parts: [DisposalPartDecision] = [],
        hazards: [DisposalHazard] = [],
        nephronEligibility: NephronEligibility? = nil
    ) {
        self.route = .category(category)
        self.objectName = objectName
        self.confidence = confidence
        self.basis = basis
        self.visibleMark = visibleMark
        self.alternatives = alternatives
        self.captureIssue = captureIssue
        self.parts = parts
        self.hazards = hazards
        self.nephronEligibility = nephronEligibility
            ?? DisposalPolicyCatalog.policy(for: .category(category)).nephronEligibility
    }

    init(
        route: DisposalRoute,
        objectName: String,
        confidence: Int,
        basis: MultimodalEvidenceBasis,
        visibleMark: String,
        alternatives: [DisposalCategory],
        captureIssue: CaptureIssue,
        parts: [DisposalPartDecision] = [],
        hazards: [DisposalHazard] = [],
        nephronEligibility: NephronEligibility? = nil
    ) {
        self.route = route
        self.objectName = objectName
        self.confidence = confidence
        self.basis = basis
        self.visibleMark = visibleMark
        self.alternatives = alternatives
        self.captureIssue = captureIssue
        self.parts = parts
        self.hazards = hazards
        self.nephronEligibility = nephronEligibility
            ?? DisposalPolicyCatalog.policy(for: route).nephronEligibility
    }
}

nonisolated struct DisposalResult: Identifiable, Sendable {
    let id = UUID()
    var route: DisposalRoute
    var source: RecognitionSource
    var confidence: Int
    var evidences: [DisposalEvidence]
    var candidates: [DisposalCategory]
    var specificSteps: [String]
    var nephronEligibility: NephronEligibility

    var category: DisposalCategory { route.legacyCategory }

    init(
        category: DisposalCategory,
        source: RecognitionSource,
        confidence: Int,
        evidences: [DisposalEvidence],
        candidates: [DisposalCategory],
        specificSteps: [String] = [],
        nephronEligibility: NephronEligibility? = nil
    ) {
        self.route = .category(category)
        self.source = source
        self.confidence = confidence
        self.evidences = evidences
        self.candidates = candidates
        self.specificSteps = specificSteps
        self.nephronEligibility = nephronEligibility
            ?? DisposalPolicyCatalog.policy(for: .category(category)).nephronEligibility
    }

    init(
        route: DisposalRoute,
        source: RecognitionSource,
        confidence: Int,
        evidences: [DisposalEvidence],
        candidates: [DisposalCategory],
        specificSteps: [String] = [],
        nephronEligibility: NephronEligibility? = nil
    ) {
        self.route = route
        self.source = source
        self.confidence = confidence
        self.evidences = evidences
        self.candidates = candidates
        self.specificSteps = specificSteps
        self.nephronEligibility = nephronEligibility
            ?? DisposalPolicyCatalog.policy(for: route).nephronEligibility
    }

    var canUseNephron: Bool {
        nephronEligibility == .likelyEligible || nephronEligibility == .checkMachine
    }

    var title: String {
        route.title
    }

    var isUncertain: Bool {
        route == .unknown
    }

    func corrected(to category: DisposalCategory) -> DisposalResult {
        corrected(to: .category(category))
    }

    func corrected(to route: DisposalRoute) -> DisposalResult {
        let policy = DisposalPolicyCatalog.policy(for: route)
        return DisposalResult(
            route: route,
            source: .userCorrection,
            confidence: 100,
            evidences: [DisposalEvidence(title: "직접 선택", detail: "사용자가 \(route.title)을 선택했어요.")],
            candidates: candidates,
            specificSteps: policy.preparationSteps,
            nephronEligibility: policy.nephronEligibility
        )
    }

}

nonisolated struct AnalysisReport: Identifiable, Sendable {
    let id = UUID()
    let result: DisposalResult
    let ocr: OCRInspection
    let aiModel: AIModelInspection

    func replacingResult(_ result: DisposalResult) -> AnalysisReport {
        AnalysisReport(
            result: result,
            ocr: ocr,
            aiModel: aiModel
        )
    }
}
