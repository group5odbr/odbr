import Foundation
import SwiftUI

enum RecognitionSource {
    case mark
    case object
    case combined
    case userCorrection

    var title: String {
        switch self {
        case .mark:
            "마크 우선"
        case .object:
            "사물 기준"
        case .combined:
            "이중 확인"
        case .userCorrection:
            "사용자 보정"
        }
    }
}

enum DisposalCategory: String, CaseIterable, Identifiable {
    case pet
    case plastic
    case vinyl
    case paper
    case can
    case glass
    case general

    var id: String { rawValue }

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
        case .can:
            "캔류"
        case .glass:
            "유리류"
        case .general:
            "일반쓰레기 후보"
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
        case .can:
            "철, 알미늄, 캔류"
        case .glass:
            "유리병"
        case .general:
            "오염, 복합재질, 마크 없음"
        }
    }

    var symbolName: String {
        switch self {
        case .pet:
            "drop.fill"
        case .plastic:
            "shippingbox.fill"
        case .vinyl:
            "bag.fill"
        case .paper:
            "doc.text.fill"
        case .can:
            "circle.fill"
        case .glass:
            "drop.triangle.fill"
        case .general:
            "trash.fill"
        }
    }

    var tint: Color {
        switch self {
        case .pet, .plastic:
            AppTheme.accent
        case .vinyl:
            Color(red: 0.196, green: 0.467, blue: 0.859)
        case .paper:
            Color(red: 0.580, green: 0.420, blue: 0.208)
        case .can:
            Color(red: 0.369, green: 0.435, blue: 0.502)
        case .glass:
            Color(red: 0.071, green: 0.514, blue: 0.561)
        case .general:
            AppTheme.warning
        }
    }

    var guideSteps: [String] {
        switch self {
        case .pet:
            ["내용물을 비우고 헹구기", "라벨과 뚜껑 분리", "가능하면 압착 후 배출"]
        case .plastic:
            ["내용물을 비우고 헹구기", "다른 재질 부착물 분리", "오염이 심하면 지자체 기준 확인"]
        case .vinyl:
            ["이물질 제거", "젖거나 오염된 비닐은 확인 필요", "비닐류 배출함에 모아 배출"]
        case .paper:
            ["테이프와 코팅 부착물 제거", "젖은 종이는 말린 뒤 확인", "상자는 펼쳐서 배출"]
        case .can:
            ["내용물을 비우기", "가능하면 가볍게 압착", "페트병과 함께 네프론 회수 가능성 확인"]
        case .glass:
            ["내용물을 비우고 헹구기", "뚜껑 분리", "깨진 유리는 신문지에 감싸 별도 배출"]
        case .general:
            ["오염 정도 확인", "분리 가능한 재질은 먼저 분리", "확신이 없으면 일반쓰레기 후보로 처리"]
        }
    }

    var canUseNephron: Bool {
        self == .pet || self == .can
    }
}

struct DisposalEvidence: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

struct DisposalResult: Identifiable {
    let id = UUID()
    var category: DisposalCategory
    var title: String
    var source: RecognitionSource
    var confidence: Int
    var evidences: [DisposalEvidence]
    var candidates: [DisposalCategory]

    var canUseNephron: Bool {
        category.canUseNephron
    }

    func corrected(to category: DisposalCategory) -> DisposalResult {
        DisposalResult(
            category: category,
            title: category.title,
            source: .userCorrection,
            confidence: 100,
            evidences: [DisposalEvidence(title: "보정", detail: "사용자가 결과를 \(category.title)로 수정")],
            candidates: DisposalCategory.allCases.filter { $0 != category }
        )
    }

    static func sample() -> DisposalResult {
        samples.randomElement() ?? samples[0]
    }

    static let samples: [DisposalResult] = [
        DisposalResult(
            category: .pet,
            title: "투명 페트병",
            source: .combined,
            confidence: 93,
            evidences: [
                DisposalEvidence(title: "마크", detail: "PET 텍스트 확인"),
                DisposalEvidence(title: "사물", detail: "병 형태와 투명 재질")
            ],
            candidates: [.plastic, .can, .general]
        ),
        DisposalResult(
            category: .vinyl,
            title: "비닐 포장재",
            source: .mark,
            confidence: 88,
            evidences: [
                DisposalEvidence(title: "마크", detail: "비닐류 키워드 확인"),
                DisposalEvidence(title: "상태", detail: "오염 여부는 추가 확인")
            ],
            candidates: [.general, .plastic, .paper]
        ),
        DisposalResult(
            category: .can,
            title: "알루미늄 캔",
            source: .object,
            confidence: 84,
            evidences: [
                DisposalEvidence(title: "사물", detail: "원통형 캔 형태"),
                DisposalEvidence(title: "마크", detail: "마크는 흐릿함")
            ],
            candidates: [.pet, .glass, .general]
        ),
        DisposalResult(
            category: .general,
            title: "오염된 복합 포장재",
            source: .object,
            confidence: 61,
            evidences: [
                DisposalEvidence(title: "사물", detail: "복합재질 가능성"),
                DisposalEvidence(title: "상태", detail: "오염이 있어 확인 필요")
            ],
            candidates: [.plastic, .vinyl, .paper]
        )
    ]
}
