import Foundation
import ImageIO
import UIKit
import Vision

nonisolated struct OCRTextObservation: Sendable {
    let text: String
    let confidence: Float
}

nonisolated struct KoreanDisposalMarkRecognizer {
    func inspect(in image: UIImage) async -> OCRInspection {
        guard let cgImage = image.cgImage else {
            return OCRInspection(
                textLines: [],
                signal: nil,
                failureReason: "촬영 이미지를 기기 내 문자 인식 형식으로 변환하지 못했어요."
            )
        }

        var recognizedObservations: [OCRTextObservation] = []
        let request = VNRecognizeTextRequest { request, _ in
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            recognizedObservations = observations.compactMap { observation in
                guard
                    let candidate = observation.topCandidates(1).first,
                    candidate.confidence >= 0.40
                else {
                    return nil
                }

                return OCRTextObservation(
                    text: candidate.string,
                    confidence: candidate.confidence
                )
            }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ko-KR", "en-US"]
        request.usesLanguageCorrection = false
        request.customWords = MarkRule.customWords

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: CGImagePropertyOrientation(image.imageOrientation),
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            return OCRInspection(
                textLines: recognizedObservations.map(\.text),
                signal: nil,
                failureReason: "기기 내 문자 인식을 완료하지 못했어요."
            )
        }

        return inspect(textObservations: recognizedObservations)
    }

    func inspect(textLines: [String]) -> OCRInspection {
        inspect(
            textObservations: textLines.map {
                OCRTextObservation(text: $0, confidence: 1)
            }
        )
    }

    func inspect(textObservations: [OCRTextObservation]) -> OCRInspection {
        let textLines = textObservations.map(\.text)
        return OCRInspection(
            textLines: textLines,
            signal: matchSignal(from: textObservations)
        )
    }

    private func matchSignal(from observations: [OCRTextObservation]) -> RecognitionSignal? {
        let textLines = observations.map(\.text)
        let normalizedText = normalize(textLines.joined(separator: " "))
        guard !normalizedText.isEmpty else {
            return nil
        }

        let matches = MarkRule.rules.compactMap { rule -> (signal: RecognitionSignal, isWeak: Bool)? in
            guard let match = firstMatch(for: rule, observations: observations) else {
                return nil
            }

            let confidence = min(
                rule.confidence,
                Int((max(0, min(1, match.observation.confidence)) * 100).rounded())
            )
            return (
                RecognitionSignal(
                    category: rule.category,
                    confidence: confidence,
                    evidence: DisposalEvidence(
                        title: rule.evidenceTitle,
                        detail: "\(match.keyword) 인식 · OCR \(confidence)%"
                    ),
                    candidates: rule.candidates
                ),
                rule.isWeakMaterialHint
            )
        }

        let preferredMatches: [(signal: RecognitionSignal, isWeak: Bool)]
        if matches.contains(where: { !$0.isWeak }) {
            preferredMatches = matches.filter { !$0.isWeak }
        } else {
            preferredMatches = matches
        }

        guard
            !preferredMatches.isEmpty,
            Set(preferredMatches.map(\.signal.category)).count == 1
        else {
            return nil
        }

        return preferredMatches
            .map(\.signal)
            .max(by: { $0.confidence < $1.confidence })
    }

    private func firstMatch(
        for rule: MarkRule,
        observations: [OCRTextObservation]
    ) -> (keyword: String, observation: OCRTextObservation)? {
        for keyword in rule.keywords {
            if let observation = observations
                .filter({ matches(keyword, in: $0, rule: rule, observations: observations) })
                .max(by: { $0.confidence < $1.confidence }) {
                return (keyword, observation)
            }
        }

        return nil
    }

    private func matches(
        _ keyword: String,
        in observation: OCRTextObservation,
        rule: MarkRule,
        observations: [OCRTextObservation]
    ) -> Bool {
        let rawTextLines = observations.map(\.text)
        let normalizedKeyword = normalize(keyword)
        guard
            normalize(observation.text).contains(normalizedKeyword),
            !isNegated(keyword, in: observation.text)
        else {
            return false
        }

        guard rule.isWeakMaterialHint else {
            return true
        }

        let materialCode = keyword.uppercased().replacingOccurrences(of: " ", with: "")
        if MarkRule.standaloneMaterialCodes.contains(materialCode) {
            return isStandaloneMaterialCode(keyword, in: [observation.text])
        }

        return hasMaterialContext(in: rawTextLines)
    }

    private func isNegated(_ keyword: String, in text: String) -> Bool {
        let normalizedText = normalize(text)
        guard normalizedText.contains(normalize(keyword)) else {
            return false
        }

        let koreanNegations = ["아님", "아닙", "아니", "제외", "불가", "금지"]
        if koreanNegations.contains(where: normalizedText.contains) {
            return true
        }

        return text.uppercased().range(
            of: "(^|[^A-Z])(NO|NOT|EXCEPT)([^A-Z]|$)",
            options: .regularExpression
        ) != nil
    }

    private func isStandaloneMaterialCode(_ keyword: String, in textLines: [String]) -> Bool {
        let code = keyword.uppercased().replacingOccurrences(of: " ", with: "")
        guard MarkRule.standaloneMaterialCodes.contains(code) else {
            return false
        }

        let rawText = textLines.joined(separator: " ").uppercased()
        let escapedCode = NSRegularExpression.escapedPattern(for: code)
        let pattern = "(^|[^A-Z0-9가-힣])\(escapedCode)([^A-Z0-9가-힣]|$)"
        return rawText.range(of: pattern, options: .regularExpression) != nil
    }

    private func hasMaterialContext(in textLines: [String]) -> Bool {
        let normalizedText = normalize(textLines.joined(separator: " "))
        return MarkRule.materialContextKeywords.contains {
            normalizedText.contains(normalize($0))
        }
    }

    private func normalize(_ text: String) -> String {
        text
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }
}

nonisolated private struct MarkRule {
    let category: DisposalCategory
    let keywords: [String]
    let confidence: Int
    let evidenceTitle: String
    let candidates: [DisposalCategory]

    var isWeakMaterialHint: Bool {
        evidenceTitle == "OCR 보조단서"
    }

    static let rules: [MarkRule] = [
        MarkRule(
            category: .pet,
            keywords: ["무색페트", "투명페트"],
            confidence: 94,
            evidenceTitle: "분리배출 표기",
            candidates: [.plastic, .can, .general]
        ),
        MarkRule(
            category: .vinyl,
            keywords: ["비닐류", "필름류"],
            confidence: 91,
            evidenceTitle: "분리배출 표기",
            candidates: [.plastic, .general, .paper]
        ),
        MarkRule(
            category: .can,
            keywords: ["캔류", "금속캔류"],
            confidence: 92,
            evidenceTitle: "분리배출 표기",
            candidates: [.pet, .glass, .general]
        ),
        MarkRule(
            category: .glass,
            keywords: ["유리류"],
            confidence: 92,
            evidenceTitle: "분리배출 표기",
            candidates: [.can, .general, .plastic]
        ),
        MarkRule(
            category: .paperPack,
            keywords: ["종이팩류", "멸균팩류"],
            confidence: 91,
            evidenceTitle: "분리배출 표기",
            candidates: [.paper, .plastic, .general]
        ),
        MarkRule(
            category: .paper,
            keywords: ["종이류"],
            confidence: 90,
            evidenceTitle: "분리배출 표기",
            candidates: [.paperPack, .general, .plastic]
        ),
        MarkRule(
            category: .styrofoam,
            keywords: ["발포합성수지류"],
            confidence: 90,
            evidenceTitle: "분리배출 표기",
            candidates: [.plastic, .general, .paper]
        ),
        MarkRule(
            category: .plastic,
            keywords: ["플라스틱류"],
            confidence: 90,
            evidenceTitle: "분리배출 표기",
            candidates: [.vinyl, .pet, .general]
        ),
        MarkRule(
            category: .pet,
            keywords: ["페트병", "PET병", "PET BOTTLE", "페트", "PETE", "PET"],
            confidence: 48,
            evidenceTitle: "OCR 보조단서",
            candidates: [.plastic, .can, .general]
        ),
        MarkRule(
            category: .vinyl,
            keywords: ["비닐", "필름", "VINYL"],
            confidence: 44,
            evidenceTitle: "OCR 보조단서",
            candidates: [.plastic, .general, .paper]
        ),
        MarkRule(
            category: .can,
            keywords: ["금속캔", "철캔", "알루미늄캔", "알미늄캔", "알루미늄", "알미늄", "철", "ALUMINUM", "ALUMINIUM", "STEEL", "ALU"],
            confidence: 45,
            evidenceTitle: "OCR 보조단서",
            candidates: [.pet, .glass, .general]
        ),
        MarkRule(
            category: .glass,
            keywords: ["유리병", "유리", "GLASS"],
            confidence: 45,
            evidenceTitle: "OCR 보조단서",
            candidates: [.can, .general, .plastic]
        ),
        MarkRule(
            category: .paperPack,
            keywords: ["종이팩", "멸균팩", "우유팩", "PAPERPACK", "PAPER PACK"],
            confidence: 48,
            evidenceTitle: "OCR 보조단서",
            candidates: [.paper, .plastic, .general]
        ),
        MarkRule(
            category: .paper,
            keywords: ["종이", "PAPER", "PAP"],
            confidence: 44,
            evidenceTitle: "OCR 보조단서",
            candidates: [.paperPack, .general, .plastic]
        ),
        MarkRule(
            category: .styrofoam,
            keywords: ["스티로폼", "발포", "발포합성수지", "EPS", "PSP"],
            confidence: 48,
            evidenceTitle: "OCR 보조단서",
            candidates: [.plastic, .general, .paper]
        ),
        MarkRule(
            category: .plastic,
            keywords: ["플라스틱", "합성수지", "PLASTIC", "HDPE", "LDPE", "PP", "PS", "PVC", "OTHER", "PE"],
            confidence: 44,
            evidenceTitle: "OCR 보조단서",
            candidates: [.vinyl, .styrofoam, .pet]
        )
    ]

    static let customWords: [String] = rules.flatMap(\.keywords) + [
        "분리배출", "재활용", "무색PET", "투명PET", "플라스틱", "비닐",
        "종이팩", "멸균팩", "발포합성수지", "알미늄", "알루미늄"
    ]

    static let standaloneMaterialCodes: Set<String> = [
        "PET", "PETE", "HDPE", "LDPE", "PP", "PS", "PVC", "OTHER",
        "PE", "EPS", "PSP", "PAP", "ALU"
    ]

    static let materialContextKeywords: [String] = [
        "분리배출", "분리", "배출", "재활용", "재질", "재질명", "소재",
        "용기", "포장재", "라벨", "뚜껑", "마크", "표시", "리사이클",
        "RECYCLE", "RECYCLING", "MATERIAL", "RESIN", "CODE"
    ]
}

nonisolated extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}
