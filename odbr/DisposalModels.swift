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
            "마크 우선"
        case .combined:
            "이중 확인"
        case .multimodalAI:
            "멀티모달 AI"
        case .localFallback:
            "로컬 안전 판정"
        case .userCorrection:
            "사용자 보정"
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
            "페트병"
        case .plastic:
            "플라스틱류"
        case .vinyl:
            "비닐류"
        case .paper:
            "종이류"
        case .paperPack:
            "종이팩류"
        case .can:
            "캔류"
        case .glass:
            "유리류"
        case .styrofoam:
            "스티로폼"
        case .general:
            "일반쓰레기"
        case .unknown:
            "판단 보류"
        }
    }

    var materialHint: String {
        switch self {
        case .pet:
            "PET, 무색페트"
        case .plastic:
            "PP, PE, PS, OTHER"
        case .vinyl:
            "비닐류, LDPE, HDPE"
        case .paper:
            "종이, PAPER"
        case .paperPack:
            "종이팩, 멸균팩, 우유팩"
        case .can:
            "철, 알루미늄, 캔류"
        case .glass:
            "유리병"
        case .styrofoam:
            "스티로폼, EPS, 발포합성수지"
        case .general:
            "비재활용 품목, 심한 오염, 복합재질"
        case .unknown:
            "재질이나 표기를 더 가까이 촬영"
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
        switch self {
        case .pet:
            ["내용물을 비우고 물로 헹구기", "라벨을 제거하기", "가능하면 압착한 뒤 뚜껑을 닫아 배출"]
        case .plastic:
            ["내용물을 비우고 헹구기", "다른 재질 부착물 분리", "오염이 심하면 지자체 기준 확인"]
        case .vinyl:
            ["이물질 제거", "젖거나 오염된 비닐은 확인 필요", "비닐류 배출함에 모아 배출"]
        case .paper:
            ["테이프와 코팅 부착물 제거", "젖은 종이는 말린 뒤 확인", "상자는 펼쳐서 배출"]
        case .paperPack:
            ["내용물을 비우고 헹구기", "빨대와 비닐 코팅 부착물 제거", "펼쳐 말린 뒤 종이팩류로 배출"]
        case .can:
            ["내용물을 비우고 이물질을 제거하기", "가능하면 가볍게 압착하기", "금속캔류 배출함 또는 지역 기준에 맞춰 배출"]
        case .glass:
            ["내용물을 비우고 물로 헹구기", "소주·맥주 빈용기보증금 대상이면 소매점 반납 확인", "깨진 유리는 신문지에 감싸 종량제·지자체 기준으로 배출"]
        case .styrofoam:
            ["테이프와 운송장 제거", "음식물이나 이물질 제거", "오염이 심하면 일반쓰레기 후보로 확인"]
        case .general:
            ["비재활용 품목인지 확인", "분리 가능한 재질은 먼저 분리", "오염·복합재질 기준은 지자체 안내 확인"]
        case .unknown:
            ["물체 하나만 화면 중앙에 놓기", "분리배출 표기나 재질이 보이게 가까이 촬영", "흔들림과 강한 반사를 피해서 다시 촬영"]
        }
    }

    var canUseNephron: Bool {
        self == .pet || self == .can
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
    let category: DisposalCategory
    let objectName: String
    let confidence: Int
    let basis: MultimodalEvidenceBasis
    let visibleMark: String
    let alternatives: [DisposalCategory]
    let captureIssue: CaptureIssue
    let parts: [DisposalPartDecision]

    init(
        category: DisposalCategory,
        objectName: String,
        confidence: Int,
        basis: MultimodalEvidenceBasis,
        visibleMark: String,
        alternatives: [DisposalCategory],
        captureIssue: CaptureIssue,
        parts: [DisposalPartDecision] = []
    ) {
        self.category = category
        self.objectName = objectName
        self.confidence = confidence
        self.basis = basis
        self.visibleMark = visibleMark
        self.alternatives = alternatives
        self.captureIssue = captureIssue
        self.parts = parts
    }
}

nonisolated struct DisposalResult: Identifiable, Sendable {
    let id = UUID()
    var category: DisposalCategory
    var source: RecognitionSource
    var confidence: Int
    var evidences: [DisposalEvidence]
    var candidates: [DisposalCategory]
    var specificSteps: [String]

    init(
        category: DisposalCategory,
        source: RecognitionSource,
        confidence: Int,
        evidences: [DisposalEvidence],
        candidates: [DisposalCategory],
        specificSteps: [String] = []
    ) {
        self.category = category
        self.source = source
        self.confidence = confidence
        self.evidences = evidences
        self.candidates = candidates
        self.specificSteps = specificSteps
    }

    var canUseNephron: Bool {
        category.canUseNephron
    }

    var title: String {
        category.title
    }

    var isUncertain: Bool {
        category == .unknown
    }

    func corrected(to category: DisposalCategory) -> DisposalResult {
        DisposalResult(
            category: category,
            source: .userCorrection,
            confidence: 100,
            evidences: [DisposalEvidence(title: "보정", detail: "사용자가 결과를 \(category.title)로 수정")],
            candidates: DisposalCategory.disposalCases.filter { $0 != category },
            specificSteps: category.guideSteps
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
