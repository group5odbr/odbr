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

    @Test func remoteConfigDefaultsPreserveSafeAISettings() throws {
        let url = try #require(Bundle.main.url(forResource: "RemoteConfigDefaults", withExtension: "plist"))
        let defaults = try #require(NSDictionary(contentsOf: url) as? [String: Any])

        #expect(defaults["ai_enabled"] as? Bool == true)
        #expect(defaults["analysis_timeout"] as? Int == 12)
        #expect(defaults["review_timeout"] as? Int == 8)
        #expect(defaults["primary_model_version"] as? String == "gemini-3.1-flash-lite")
        #expect(defaults["review_model_version"] as? String == "gemini-3.5-flash")
    }

    @Test func onlineFailureReasonIsShownWhenNoLocalEvidenceExists() {
        let result = DisposalDecisionEngine.result(
            multimodalDecision: nil,
            localMark: nil,
            onlineFailureReason: "Gemini 서버가 일시적으로 혼잡해 정밀 판정을 완료하지 못했어요."
        )

        #expect(result.category == .unknown)
        #expect(result.evidences.contains {
            $0.title == "다시 확인이 필요해요" && $0.detail.contains("Gemini 서버가 일시적으로 혼잡")
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
            $0.title == "AI 추가 확인 불가" && $0.detail == serverReason
        })
        #expect(result.evidences.contains { $0.title == "다시 확인이 필요해요" })
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

    @Test func productCatalogHasTheRequiredOfflineCoverage() {
        #expect(ProductSearchCatalog.families.count >= 65)
        let aliases = ProductSearchCatalog.families.flatMap(\.aliases)
        #expect(aliases.count >= 150)
        #expect(Set(ProductSearchCatalog.families.map(\.id)).count == ProductSearchCatalog.families.count)
    }

    @Test func colaSearchKeepsAllCommonPackageChoices() {
        let repository = ProductSearchRepository()
        let hit = repository.search("코카 콜라").first

        #expect(hit?.family.id == "cola")
        #expect(hit?.family.variants.map(\.destination).contains(.category(.can)) == true)
        #expect(hit?.family.variants.map(\.destination).contains(.category(.pet)) == true)
        #expect(hit?.family.variants.map(\.destination).contains(.category(.glass)) == true)
    }

    @Test func colaPetChoiceContainsPartsAndCorrectSeparationPolicies() {
        let cola = ProductSearchCatalog.families.first { $0.id == "cola" }
        let pet = cola?.variants.first { $0.id.hasSuffix("-pet") }

        #expect(pet?.destination == .category(.pet))
        #expect(pet?.parts.first { $0.name == "라벨" }?.destination == .category(.vinyl))
        #expect(pet?.parts.first { $0.name == "뚜껑" }?.separation == .keepAttached)
    }

    @Test func productShapeWordsPrioritizeTheMatchingVariantWithoutAutoSelectingIt() {
        let repository = ProductSearchRepository()
        let cola = repository.search("페트병콜라").first
        let soju = repository.search("유리공병 소주병").first

        #expect(cola?.family.id == "cola")
        #expect(cola?.matchedVariantIDs.first?.hasSuffix("-pet") == true)
        #expect(soju?.family.id == "soju")
        #expect(soju?.matchedVariantIDs.first?.hasSuffix("-returnableGlass") == true)
    }

    @Test func sojuAndDollSearchExposeMaterialAndSpecialRoutes() {
        let repository = ProductSearchRepository()
        let soju = repository.search("참이슬").first?.family.variants ?? []
        let doll = repository.search("인형").first?.family.variants ?? []

        #expect(soju.contains { $0.destination == .depositReturn && $0.flags.contains(.returnDepositBottle) })
        #expect(soju.contains { $0.destination == .category(.plastic) })
        #expect(doll.contains { $0.destination == .largeWaste })
        #expect(doll.contains { $0.destination == .smallElectronicsCollection })
    }

    @Test func productSearchNormalizesBrandSpacingAndCase() {
        let repository = ProductSearchRepository()

        #expect(repository.search("Coca-Cola").first?.family.id == "cola")
        #expect(repository.search("  PET 소주병 ").first?.family.id == "soju")
        #expect(repository.search("보조 배터리").first?.family.id == "power_bank")
    }

    @Test func productSearchCacheExpiresAndKeepsOnlyCatalogMappings() {
        let suiteName = "odbr.product-search-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let cache = ProductSearchCache(defaults: defaults)

        cache.save(familyID: "cola", for: "테스트", now: Date(timeIntervalSince1970: 100))
        #expect(cache.value(for: "테스트", now: Date(timeIntervalSince1970: 100 + 60)) == "cola")
        #expect(cache.value(for: "테스트", now: Date(timeIntervalSince1970: 100 + 31 * 24 * 60 * 60)) == nil)
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test func officialPetGuideUsesLabelRemovalAndClosedCap() {
        #expect(DisposalCategory.pet.guideSteps.contains { $0.contains("라벨") })
        #expect(DisposalCategory.pet.guideSteps.contains { $0.contains("뚜껑을 닫아") })
    }

    @Test func policyCatalogCoversEverySelectableRouteWithSourceAndReviewDate() {
        let policies = DisposalPolicyCatalog.policies
        let routes = Set(policies.map(\.route))

        #expect(routes == Set(DisposalRoute.selectableCases + [.unknown]))
        #expect(policies.allSatisfy { !$0.sourceID.isEmpty })
        #expect(policies.allSatisfy { !$0.reviewedAt.isEmpty })
        #expect(policies.allSatisfy { !$0.effectiveDate.isEmpty })
    }

    @Test func clearPetRequiresClearBeverageBottleObservations() {
        let clearBottle = observation(material: .pet, form: .beverageBottle, transparency: .clear)
        let coloredBottle = observation(material: .pet, form: .beverageBottle, transparency: .colored)
        let petTray = observation(material: .pet, form: .rigidContainerTray, transparency: .clear)

        #expect(ObservationPolicyEngine.route(for: clearBottle) == .recyclable(.clearPETBottle))
        #expect(ObservationPolicyEngine.route(for: coloredBottle) == .recyclable(.plasticContainerTray))
        #expect(ObservationPolicyEngine.route(for: petTray) == .recyclable(.plasticContainerTray))
    }

    @Test func hazardsOverrideOrdinaryRecyclingRoutes() {
        let pressureCan = observation(material: .metal, form: .beverageCan, hazards: [.pressurizedContainer])
        let brokenBottle = observation(material: .glass, form: .glassBottle, hazards: [.brokenGlass, .sharpObject])
        let damagedBattery = observation(material: .plastic, form: .battery, hazards: [.damagedBattery])

        #expect(ObservationPolicyEngine.route(for: pressureCan) == .householdHazardousWaste)
        #expect(ObservationPolicyEngine.route(for: brokenBottle) == .specialWasteBag)
        #expect(ObservationPolicyEngine.route(for: damagedBattery) == .householdHazardousWaste)
    }

    @Test func highRiskCatalogItemsNeverUseOrdinaryRecyclingRoutes() {
        let repository = ProductSearchRepository()
        let receipt = repository.search("영수증").first?.family.variants ?? []
        let tissue = repository.search("키친타월").first?.family.variants ?? []
        let cookware = repository.search("프라이팬").first?.family.variants ?? []
        let powerBank = repository.search("보조배터리").first?.family.variants ?? []
        let brokenLighting = repository.search("깨진 형광등").first?.family.variants.first { $0.id.hasSuffix("-broken") }
        let rubberGlove = repository.search("고무장갑").first?.family.variants ?? []

        #expect(!receipt.contains { $0.destination == .recyclable(.paper) })
        #expect(!tissue.contains { $0.destination == .recyclable(.paper) })
        #expect(cookware.contains { $0.destination == .recyclable(.metalScrap) })
        #expect(!cookware.contains { $0.destination == .recyclable(.metalCan) })
        #expect(powerBank.allSatisfy { !$0.parts.contains { $0.name.contains("내장 배터리") } })
        #expect(powerBank.contains { $0.flags.contains(.doNotDisassemble) })
        #expect(brokenLighting?.destination != .lightingCollection)
        #expect(!rubberGlove.contains { $0.destination == .recyclable(.vinylPackaging) })
    }

    @Test func correctionCandidatesPreserveModelOrderAndIncludeSpecialRoutes() {
        let result = DisposalResult(
            category: .plastic,
            source: .multimodalAI,
            confidence: 80,
            evidences: [],
            candidates: [.vinyl, .paperPack, .can]
        )

        #expect(CorrectionCandidateBuilder.ranked(for: result).map(\.route) == [
            .recyclable(.vinylPackaging),
            .recyclable(.paperPack),
            .recyclable(.metalCan)
        ])
        #expect(CorrectionCandidateBuilder.allRoutes(excluding: result).contains(.batteryCollection))
        #expect(CorrectionCandidateBuilder.allRoutes(excluding: result).contains(.householdHazardousWaste))
    }

    @Test func nephronEligibilityIsNotGrantedToGenericPetOrMetalObjects() {
        #expect(DisposalPolicyCatalog.policy(for: .recyclable(.clearPETBottle)).nephronEligibility == .likelyEligible)
        #expect(DisposalPolicyCatalog.policy(for: .recyclable(.metalCan)).nephronEligibility == .checkMachine)
        #expect(DisposalPolicyCatalog.policy(for: .recyclable(.plasticContainerTray)).nephronEligibility == .notEligible)
        #expect(DisposalPolicyCatalog.policy(for: .recyclable(.metalScrap)).nephronEligibility == .notEligible)

        let beverageCan = ObservationPolicyEngine.decision(
            from: observation(material: .metal, form: .beverageCan)
        )
        let foodCan = ObservationPolicyEngine.decision(
            from: observation(material: .metal, form: .foodCan)
        )
        #expect(beverageCan.nephronEligibility == .checkMachine)
        #expect(foodCan.nephronEligibility == .notEligible)
    }

    private func observation(
        material: ObservedMaterial,
        form: PackageForm,
        transparency: Transparency = .unknown,
        hazards: [DisposalHazard] = []
    ) -> WasteObservation {
        WasteObservation(
            objectCandidates: ["테스트 품목"],
            materialCandidates: [material],
            packageForm: form,
            transparency: transparency,
            visibleMark: "",
            contamination: .clean,
            parts: [],
            hazards: hazards,
            captureIssue: .none,
            confidence: 90
        )
    }
}

private struct DescribedTestError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
