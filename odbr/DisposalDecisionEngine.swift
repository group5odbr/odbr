import Foundation

nonisolated enum DisposalDecisionEngine {
    static func result(
        multimodalDecision: MultimodalDisposalDecision?,
        localMark: RecognitionSignal?,
        onlineFailureReason: String? = nil
    ) -> DisposalResult {
        let strongMark = localMark.flatMap { $0.confidence >= 85 ? $0 : nil }

        guard let decision = multimodalDecision else {
            if let strongMark {
                return resultFromMark(strongMark)
            }

            return unknownResult(
                reason: onlineFailureReason ?? "AI 사진 분석을 사용할 수 없고, 알아볼 수 있는 분리배출 표시도 찾지 못했어요.",
                candidates: [],
                source: .localFallback
            )
        }

        if decision.captureIssue == .multipleObjects || isBlockingCaptureIssue(decision.captureIssue) {
            return unknownResult(
                reason: decision.captureIssue.guidance,
                candidates: decision.alternatives + [decision.category]
            )
        }

        if let strongMark {
            if strongMark.category == decision.category {
                if isDecisionSupported(decision, localMark: strongMark) {
                    return makeResult(
                        route: decision.route,
                        source: .combined,
                        confidence: min(96, max(strongMark.confidence, calibratedConfidence(for: decision)) + 2),
                        evidences: [
                            strongMark.evidence,
                            aiEvidence(for: decision)
                        ],
                        candidates: decision.alternatives + strongMark.candidates,
                        specificSteps: specificSteps(for: decision),
                        nephronEligibility: decision.nephronEligibility
                    )
                }

                return resultFromMark(strongMark)
            }

            if decision.basis == .explicitMark {
                return unknownResult(
                    reason: "사진 분석과 분리배출 표시가 서로 다른 결과를 보여요. 표시를 정면에서 다시 찍어 주세요.",
                    evidences: [strongMark.evidence, aiEvidence(for: decision)],
                    candidates: [decision.category, strongMark.category] + decision.alternatives
                )
            }

            return makeResult(
                category: strongMark.category,
                source: .mark,
                confidence: strongMark.confidence,
                evidences: [
                    strongMark.evidence,
                    DisposalEvidence(title: "분리배출 표시 우선", detail: "물건 모양보다 사진에서 선명하게 읽힌 표시를 먼저 확인했어요.")
                ],
                candidates: [decision.category] + decision.alternatives + strongMark.candidates
            )
        }

        guard isDecisionSupported(decision, localMark: localMark) else {
            let onlineFailureEvidence = onlineFailureReason.map {
                DisposalEvidence(title: "AI 추가 확인 불가", detail: $0)
            }
            return unknownResult(
                reason: uncertaintyReason(for: decision),
                evidences: [aiEvidence(for: decision), onlineFailureEvidence].compactMap { $0 },
                candidates: decision.alternatives + [decision.category]
            )
        }

        let verifiedExplicitMark = decision.basis == .explicitMark ? localMark : nil
        return makeResult(
            route: decision.route,
            source: verifiedExplicitMark == nil ? .multimodalAI : .combined,
            confidence: calibratedConfidence(for: decision),
            evidences: [verifiedExplicitMark?.evidence, aiEvidence(for: decision)].compactMap { $0 },
            candidates: decision.alternatives,
            specificSteps: specificSteps(for: decision),
            nephronEligibility: decision.nephronEligibility
        )
    }

    private static func isDecisionSupported(
        _ decision: MultimodalDisposalDecision,
        localMark: RecognitionSignal?
    ) -> Bool {
        guard decision.route != .unknown else {
            return false
        }

        if decision.basis == .safetyHazard {
            return !decision.hazards.isEmpty && decision.confidence >= 75
        }

        switch decision.basis {
        case .explicitMark:
            let visibleMark = decision.visibleMark.trimmingCharacters(in: .whitespacesAndNewlines)
            guard
                decision.category != .general,
                decision.captureIssue != .markUnreadable,
                !visibleMark.isEmpty,
                visibleMarkMatches(visibleMark, category: decision.category),
                let localMark,
                localMark.confidence >= 40,
                localMark.category == decision.category
            else {
                return false
            }
        case .nonRecyclableItem, .contamination, .composite:
            guard decision.category == .general else {
                return false
            }
        case .materialAndShape, .materialOnly:
            guard decision.category != .general else {
                return false
            }
        case .shapeOnly, .conflicting, .insufficient:
            return false
        case .safetyHazard:
            break
        }

        return calibratedConfidence(for: decision) >= minimumConfidence(for: decision.basis)
    }

    private static func calibratedConfidence(for decision: MultimodalDisposalDecision) -> Int {
        let raw = max(0, min(100, decision.confidence))

        switch decision.basis {
        case .explicitMark:
            return min(raw, 96)
        case .materialAndShape:
            return min(raw, 90)
        case .materialOnly:
            return min(raw, 82)
        case .shapeOnly:
            return min(raw, 70)
        case .nonRecyclableItem:
            return min(raw, 88)
        case .contamination, .composite:
            return min(raw, 84)
        case .safetyHazard:
            return min(raw, 92)
        case .conflicting:
            return min(raw, 50)
        case .insufficient:
            return min(raw, 45)
        }
    }

    static func minimumConfidence(for basis: MultimodalEvidenceBasis) -> Int {
        switch basis {
        case .explicitMark:
            78
        case .materialAndShape:
            72
        case .materialOnly:
            78
        case .nonRecyclableItem, .contamination, .composite, .safetyHazard:
            75
        case .shapeOnly, .conflicting, .insufficient:
            101
        }
    }

    private static func isBlockingCaptureIssue(_ issue: CaptureIssue) -> Bool {
        switch issue {
        case .blurred, .tooFar, .cropped:
            true
        case .none, .multipleObjects, .markUnreadable:
            false
        }
    }

    private static func uncertaintyReason(for decision: MultimodalDisposalDecision) -> String {
        if decision.basis == .shapeOnly {
            return "모양은 보이지만 재질을 확인하지 못했어요. 재질이나 분리배출 표기가 보이게 다시 촬영해 주세요."
        }

        if decision.basis == .conflicting {
            return "사진 속 표시와 재질 정보가 서로 달라 다시 확인이 필요해요."
        }

        if decision.category == .general {
            return "사진만으로 일반쓰레기인지 확실하지 않아요. 오염 상태와 재질이 보이게 다시 찍어 주세요."
        }

        return decision.captureIssue == .none
            ? "분리배출 종류를 확정할 근거가 부족해요. 물체와 표기를 더 선명하게 촬영해 주세요."
            : decision.captureIssue.guidance
    }

    private static func aiEvidence(for decision: MultimodalDisposalDecision) -> DisposalEvidence {
        let objectName = sanitized(decision.objectName, limit: 40)
        let basisDescription: String

        switch decision.basis {
        case .explicitMark:
            basisDescription = "사진에서 분리배출 표시를 확인했어요."
        case .materialAndShape:
            basisDescription = "물건의 재질과 모양을 함께 확인했어요."
        case .materialOnly:
            basisDescription = "사진에서 물건의 재질을 확인했어요."
        case .nonRecyclableItem:
            basisDescription = "재활용하기 어려운 물건으로 확인했어요."
        case .contamination:
            basisDescription = "재활용을 어렵게 하는 심한 오염을 확인했어요."
        case .composite:
            basisDescription = "서로 다른 재질을 떼기 어려운 물건으로 확인했어요."
        case .safetyHazard:
            basisDescription = "가스·깨진 부분·배터리처럼 주의할 점을 먼저 확인했어요."
        case .shapeOnly, .conflicting, .insufficient:
            basisDescription = "사진만으로 확실하게 판단하기 어려워요."
        }

        return DisposalEvidence(
            title: "사진에서 확인한 내용",
            detail: objectName.isEmpty ? basisDescription : "\(objectName) · \(basisDescription)"
        )
    }

    private static func visibleMarkMatches(_ mark: String, category: DisposalCategory) -> Bool {
        let normalized = mark
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        let aliases: [String]
        switch category {
        case .pet:
            aliases = ["무색페트", "투명페트"]
        case .plastic:
            aliases = ["플라스틱", "HDPE", "LDPE", "PP", "PVC", "OTHER", "PE"]
        case .vinyl:
            aliases = ["비닐", "필름", "VINYL"]
        case .paper:
            guard !normalized.contains("종이팩") && !normalized.contains("PAPERPACK") else {
                return false
            }
            aliases = ["종이류", "PAPER", "PAP"]
        case .paperPack:
            aliases = ["종이팩", "멸균팩", "PAPERPACK"]
        case .can:
            aliases = ["캔류", "금속캔", "알루미늄", "철캔", "ALUMINUM", "STEEL", "ALU"]
        case .glass:
            aliases = ["유리류", "유리병", "GLASS"]
        case .styrofoam:
            aliases = ["스티로폼", "발포합성수지", "EPS", "PSP"]
        case .general, .unknown:
            return false
        }

        return aliases.contains { normalized.contains($0) }
    }

    private static func specificSteps(for decision: MultimodalDisposalDecision) -> [String] {
        var seen = Set<String>()
        return decision.parts
            .prefix(4)
            .compactMap { part in
                let component = sanitized(part.component, limit: 16)
                guard !component.isEmpty, part.category != .unknown else {
                    return nil
                }

                if component.contains("라벨") || component.contains("스티커") {
                    return "\(component): 떼어낸 뒤 \(part.category.title)로 분리배출"
                }

                if component.contains("뚜껑") || component.contains("마개") {
                    return "\(component): 본체에서 분리해 \(part.category.title)로 배출"
                }

                return "\(component): \(part.category.title)로 분리배출"
            }
            .filter { seen.insert($0).inserted }
    }

    private static func sanitized(_ value: String, limit: Int) -> String {
        String(
            value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .filter { !$0.isNewline }
                .prefix(limit)
        )
    }

    private static func resultFromMark(_ mark: RecognitionSignal) -> DisposalResult {
        makeResult(
            category: mark.category,
            source: .mark,
            confidence: mark.confidence,
            evidences: [mark.evidence],
            candidates: mark.candidates
        )
    }

    private static func unknownResult(
        reason: String,
        evidences: [DisposalEvidence] = [],
        candidates: [DisposalCategory],
        source: RecognitionSource = .multimodalAI
    ) -> DisposalResult {
        makeResult(
            category: .unknown,
            source: source,
            confidence: 0,
            evidences: evidences + [DisposalEvidence(title: "다시 확인이 필요해요", detail: reason)],
            candidates: candidates
        )
    }

    private static func makeResult(
        category: DisposalCategory,
        source: RecognitionSource,
        confidence: Int,
        evidences: [DisposalEvidence],
        candidates: [DisposalCategory],
        specificSteps: [String] = [],
        nephronEligibility: NephronEligibility? = nil
    ) -> DisposalResult {
        makeResult(
            route: .category(category),
            source: source,
            confidence: confidence,
            evidences: evidences,
            candidates: candidates,
            specificSteps: specificSteps,
            nephronEligibility: nephronEligibility
        )
    }

    private static func makeResult(
        route: DisposalRoute,
        source: RecognitionSource,
        confidence: Int,
        evidences: [DisposalEvidence],
        candidates: [DisposalCategory],
        specificSteps: [String] = [],
        nephronEligibility: NephronEligibility? = nil
    ) -> DisposalResult {
        let policy = DisposalPolicyCatalog.policy(for: route)
        return DisposalResult(
            route: route,
            source: source,
            confidence: max(0, min(100, confidence)),
            evidences: evidences,
            candidates: mergeCandidates(candidates, defaultCandidates(for: route.legacyCategory), excluding: route.legacyCategory),
            specificSteps: specificSteps.isEmpty ? policy.preparationSteps : specificSteps,
            nephronEligibility: nephronEligibility
        )
    }

    private static func mergeCandidates(
        _ primary: [DisposalCategory],
        _ defaults: [DisposalCategory],
        excluding category: DisposalCategory
    ) -> [DisposalCategory] {
        var seen = Set([category, .unknown])
        return (primary + defaults)
            .filter { seen.insert($0).inserted }
            .prefix(3)
            .map { $0 }
    }

    private static func defaultCandidates(for category: DisposalCategory) -> [DisposalCategory] {
        switch category {
        case .pet:
            [.plastic, .can, .glass]
        case .plastic:
            [.vinyl, .pet, .general]
        case .vinyl:
            [.plastic, .general, .paper]
        case .paper:
            [.paperPack, .general, .plastic]
        case .paperPack:
            [.paper, .plastic, .general]
        case .can:
            [.pet, .glass, .general]
        case .glass:
            [.can, .general, .plastic]
        case .styrofoam:
            [.plastic, .general, .paper]
        case .general, .unknown:
            [.plastic, .vinyl, .paper, .paperPack, .styrofoam]
        }
    }
}
