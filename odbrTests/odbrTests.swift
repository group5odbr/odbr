//
//  odbrTests.swift
//  odbrTests
//
//  Created by 이현규 on 7/7/26.
//

import Foundation
import Testing
@testable import odbr

struct odbrTests {

    @Test func multimodalRequestTimeoutAllowsMobileImageAnalysis() {
        #expect(MultimodalDisposalInferencer.requestTimeout == 12)
        #expect(MultimodalDisposalInferencer.precisionReviewTimeout == 8)
        #expect(MultimodalDisposalInferencer.primaryModelName == "gemini-3.1-flash-lite")
        #expect(MultimodalDisposalInferencer.precisionReviewModelName == "gemini-3.5-flash")
    }

    @Test func onlineFailureReasonIsShownWhenNoLocalEvidenceExists() {
        let result = DisposalDecisionEngine.result(
            multimodalDecision: nil,
            localMark: nil,
            onlineFailureReason: "Gemini 서버가 일시적으로 혼잡해 정밀 판정을 완료하지 못했어요."
        )

        #expect(result.category == .unknown)
        #expect(result.evidences.contains {
            $0.title == "판정 보류" && $0.detail.contains("Gemini 서버가 일시적으로 혼잡")
        })
    }

    @Test func precisionFailureReasonIsPreservedWhenLiteDecisionAbstains() {
        let decision = MultimodalDisposalDecision(
            category: .unknown,
            objectName: "재질을 알 수 없는 용기",
            confidence: 51,
            basis: .insufficient,
            visibleMark: "",
            alternatives: [.plastic, .vinyl],
            captureIssue: .none
        )
        let serverReason = "Gemini 무료 이용량이 일시적으로 초과됐어요. 잠시 후 다시 시도해 주세요."

        let result = DisposalDecisionEngine.result(
            multimodalDecision: decision,
            localMark: nil,
            onlineFailureReason: serverReason
        )

        #expect(result.category == .unknown)
        #expect(result.evidences.contains {
            $0.title == "온라인 정밀 판정 불가" && $0.detail == serverReason
        })
        #expect(result.evidences.contains { $0.title == "판정 보류" })
    }

    @Test func ocrProductCopyDoesNotCreateWeakMaterialSignal() {
        let ocr = KoreanDisposalMarkRecognizer().inspect(textLines: [
            "OPEN HERE",
            "SUPER SNACK",
            "Coca-Cola"
        ])

        #expect(ocr.signal?.category == nil)
    }

    @Test func ocrMaterialCodeRequiresMaterialContext() {
        let ocr = KoreanDisposalMarkRecognizer().inspect(textLines: [
            "분리배출",
            "재질: PP"
        ])

        #expect(ocr.signal?.category == .plastic)
    }

    @Test func materialContextDoesNotTurnProductTextSubstringIntoAResinCode() {
        let ocr = KoreanDisposalMarkRecognizer().inspect(textLines: [
            "재활용 포장",
            "OPEN HERE"
        ])

        #expect(ocr.signal == nil)
    }

    @Test func negatedDisposalMarkIsIgnored() {
        let ocr = KoreanDisposalMarkRecognizer().inspect(textLines: ["비닐류 아님"])

        #expect(ocr.signal == nil)
    }

    @Test func conflictingExplicitDisposalMarksAreIgnored() {
        let ocr = KoreanDisposalMarkRecognizer().inspect(textLines: [
            "비닐류",
            "플라스틱류"
        ])

        #expect(ocr.signal == nil)
    }

    @Test func explicitMarkTakesPriorityOverWeakMaterialCode() {
        let ocr = KoreanDisposalMarkRecognizer().inspect(textLines: [
            "분리배출 비닐류",
            "재질 PP"
        ])

        #expect(ocr.signal?.category == .vinyl)
    }

    @Test func ocrDoesNotJoinSeparateObservationsIntoAFalseDisposalMark() {
        let ocr = KoreanDisposalMarkRecognizer().inspect(textLines: [
            "종이",
            "팩"
        ])

        #expect(ocr.signal == nil)
    }

    @Test func lowConfidenceOCRCannotBecomeAStrongDisposalMark() {
        let ocr = KoreanDisposalMarkRecognizer().inspect(textObservations: [
            OCRTextObservation(text: "비닐류", confidence: 0.62)
        ])
        let result = DisposalDecisionEngine.result(
            multimodalDecision: nil,
            localMark: ocr.signal
        )

        #expect(ocr.signal?.confidence == 62)
        #expect(result.category == .unknown)
        #expect(result.source == .localFallback)
    }

    @Test func lowConfidenceSupportedBasisRequestsPrecisionReview() {
        let lowConfidence = MultimodalDisposalDecision(
            category: .plastic,
            objectName: "플라스틱 용기",
            confidence: 60,
            basis: .materialAndShape,
            visibleMark: "",
            alternatives: [.vinyl],
            captureIssue: .none
        )
        let supportedConfidence = MultimodalDisposalDecision(
            category: .plastic,
            objectName: "플라스틱 용기",
            confidence: 78,
            basis: .materialAndShape,
            visibleMark: "",
            alternatives: [.vinyl],
            captureIssue: .none
        )

        #expect(MultimodalDisposalInferencer.needsPrecisionReview(lowConfidence))
        #expect(!MultimodalDisposalInferencer.needsPrecisionReview(supportedConfidence))
    }

    @Test func blockingCaptureIssueDoesNotSpendPrecisionRequest() {
        let decision = MultimodalDisposalDecision(
            category: .unknown,
            objectName: "흐린 용기",
            confidence: 40,
            basis: .insufficient,
            visibleMark: "",
            alternatives: [.plastic],
            captureIssue: .blurred
        )

        #expect(!MultimodalDisposalInferencer.needsPrecisionReview(decision))
    }

    @Test func firebaseFailuresAreMappedToActionableReasons() {
        #expect(MultimodalDisposalInferencer.failureReason(for: URLError(.timedOut)).contains("제한 시간"))
        #expect(MultimodalDisposalInferencer.failureReason(for: URLError(.notConnectedToInternet)).contains("네트워크 연결"))
        #expect(MultimodalDisposalInferencer.failureReason(for: DescribedTestError("httpResponseCode: 503")).contains("서버가 일시적으로 혼잡"))
    }

    @Test func insufficientMultimodalEvidenceAbstainsInsteadOfCallingItGeneralWaste() {
        let decision = MultimodalDisposalDecision(
            category: .general,
            objectName: "식별하기 어려운 포장재",
            confidence: 93,
            basis: .insufficient,
            visibleMark: "",
            alternatives: [.plastic, .vinyl],
            captureIssue: .tooFar
        )

        let result = DisposalDecisionEngine.result(
            multimodalDecision: decision,
            localMark: nil
        )

        #expect(result.category == .unknown)
        #expect(result.confidence <= 55)
        #expect(result.candidates.first == .plastic)
    }

    @Test func explicitLocalMarkBeatsShapeOnlyMultimodalGuess() {
        let decision = MultimodalDisposalDecision(
            category: .plastic,
            objectName: "포장 용기",
            confidence: 91,
            basis: .shapeOnly,
            visibleMark: "",
            alternatives: [.vinyl],
            captureIssue: .none
        )
        let mark = RecognitionSignal(
            category: .vinyl,
            confidence: 91,
            evidence: DisposalEvidence(title: "분리배출 표기", detail: "비닐류 인식"),
            candidates: [.plastic, .general]
        )

        let result = DisposalDecisionEngine.result(
            multimodalDecision: decision,
            localMark: mark
        )

        #expect(result.category == .vinyl)
        #expect(result.source == .mark)
    }

    @Test func conflictingExplicitMarksAbstainInsteadOfPickingOne() {
        let decision = MultimodalDisposalDecision(
            category: .plastic,
            objectName: "포장 용기",
            confidence: 94,
            basis: .explicitMark,
            visibleMark: "플라스틱류",
            alternatives: [.vinyl],
            captureIssue: .none
        )
        let mark = RecognitionSignal(
            category: .vinyl,
            confidence: 91,
            evidence: DisposalEvidence(title: "분리배출 표기", detail: "비닐류 인식"),
            candidates: [.plastic, .general]
        )

        let result = DisposalDecisionEngine.result(
            multimodalDecision: decision,
            localMark: mark
        )

        #expect(result.category == .unknown)
        #expect(result.candidates.contains(.plastic))
        #expect(result.candidates.contains(.vinyl))
    }

    @Test func clearNonRecyclableItemCanStillResolveToGeneralWaste() {
        let decision = MultimodalDisposalDecision(
            category: .general,
            objectName: "사용한 마스크",
            confidence: 88,
            basis: .nonRecyclableItem,
            visibleMark: "",
            alternatives: [],
            captureIssue: .none
        )

        let result = DisposalDecisionEngine.result(
            multimodalDecision: decision,
            localMark: nil
        )

        #expect(result.category == .general)
        #expect(result.source == .multimodalAI)
        #expect(result.confidence >= 75)
    }

    @Test func multipleObjectsAbstainEvenWhenLocalOCRFindsAMark() {
        let decision = MultimodalDisposalDecision(
            category: .vinyl,
            objectName: "여러 포장재",
            confidence: 92,
            basis: .explicitMark,
            visibleMark: "비닐류",
            alternatives: [.plastic],
            captureIssue: .multipleObjects
        )
        let mark = RecognitionSignal(
            category: .vinyl,
            confidence: 91,
            evidence: DisposalEvidence(title: "분리배출 표기", detail: "비닐류 인식"),
            candidates: [.plastic, .general]
        )

        let result = DisposalDecisionEngine.result(
            multimodalDecision: decision,
            localMark: mark
        )

        #expect(result.category == .unknown)
    }

    @Test func modelClaimedExplicitMarkRequiresMatchingLocalOCR() {
        let decision = MultimodalDisposalDecision(
            category: .vinyl,
            objectName: "포장 봉지",
            confidence: 94,
            basis: .explicitMark,
            visibleMark: "비닐류",
            alternatives: [.plastic],
            captureIssue: .none
        )

        let result = DisposalDecisionEngine.result(
            multimodalDecision: decision,
            localMark: nil
        )

        #expect(result.category == .unknown)
    }

    @Test func explicitMarkMustSemanticallyMatchItsCategory() {
        let decision = MultimodalDisposalDecision(
            category: .plastic,
            objectName: "포장 봉지",
            confidence: 94,
            basis: .explicitMark,
            visibleMark: "비닐류",
            alternatives: [.vinyl],
            captureIssue: .none
        )
        let weakLocalMark = RecognitionSignal(
            category: .plastic,
            confidence: 48,
            evidence: DisposalEvidence(title: "OCR 보조단서", detail: "PP 인식"),
            candidates: [.vinyl]
        )

        let result = DisposalDecisionEngine.result(
            multimodalDecision: decision,
            localMark: weakLocalMark
        )

        #expect(result.category == .unknown)
    }

    @Test func semanticBasisCannotResolveARecyclableCategoryAsNonRecyclable() {
        let decision = MultimodalDisposalDecision(
            category: .plastic,
            objectName: "플라스틱 용기",
            confidence: 90,
            basis: .nonRecyclableItem,
            visibleMark: "",
            alternatives: [.general],
            captureIssue: .none
        )

        let result = DisposalDecisionEngine.result(
            multimodalDecision: decision,
            localMark: nil
        )

        #expect(result.category == .unknown)
    }

    @Test func blockingCaptureIssueCannotBeBypassedByStrongOCR() {
        let decision = MultimodalDisposalDecision(
            category: .vinyl,
            objectName: "흐린 포장재",
            confidence: 93,
            basis: .explicitMark,
            visibleMark: "비닐류",
            alternatives: [.plastic],
            captureIssue: .blurred
        )
        let strongMark = RecognitionSignal(
            category: .vinyl,
            confidence: 91,
            evidence: DisposalEvidence(title: "분리배출 표기", detail: "비닐류 인식"),
            candidates: [.plastic]
        )

        let result = DisposalDecisionEngine.result(
            multimodalDecision: decision,
            localMark: strongMark
        )

        #expect(result.category == .unknown)
    }

    @Test func visiblePartsBecomeLocalControlledDisposalSteps() {
        let decision = MultimodalDisposalDecision(
            category: .pet,
            objectName: "투명 생수병",
            confidence: 88,
            basis: .materialAndShape,
            visibleMark: "",
            alternatives: [.plastic],
            captureIssue: .none,
            parts: [
                DisposalPartDecision(component: "본체", category: .pet),
                DisposalPartDecision(component: "라벨", category: .vinyl),
                DisposalPartDecision(component: "뚜껑", category: .plastic)
            ]
        )

        let result = DisposalDecisionEngine.result(
            multimodalDecision: decision,
            localMark: nil
        )

        #expect(result.category == .pet)
        #expect(result.specificSteps.count == 3)
        #expect(result.specificSteps.contains { $0.contains("라벨") && $0.contains("비닐류") })
    }
}

private struct DescribedTestError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
