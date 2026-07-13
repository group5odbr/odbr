import Foundation

nonisolated enum ObservedMaterial: String, Codable, CaseIterable, Sendable {
    case pet
    case plastic
    case vinyl
    case paper
    case paperPack
    case metal
    case glass
    case foam
    case textile
    case food
    case mixed
    case unknown
}

nonisolated enum PackageForm: String, Codable, CaseIterable, Sendable {
    case beverageBottle
    case rigidContainerTray
    case flexibleFilmPouch
    case paperItem
    case liquidCarton
    case beverageCan
    case foodCan
    case glassBottle
    case foamPackaging
    case metalCookware
    case battery
    case smallElectronics
    case lighting
    case clothing
    case foodScrap
    case nonRecyclableItem
    case unknown
}

nonisolated enum Transparency: String, Codable, CaseIterable, Sendable {
    case clear
    case colored
    case opaque
    case unknown
}

nonisolated enum ContaminationLevel: String, Codable, CaseIterable, Sendable {
    case clean
    case light
    case severe
    case unknown
}

nonisolated struct ObservedPart: Codable, Equatable, Sendable {
    let name: String
    let material: ObservedMaterial
    let packageForm: PackageForm
}

nonisolated struct WasteObservation: Codable, Equatable, Sendable {
    let objectCandidates: [String]
    let materialCandidates: [ObservedMaterial]
    let packageForm: PackageForm
    let transparency: Transparency
    let visibleMark: String
    let contamination: ContaminationLevel
    let parts: [ObservedPart]
    let hazards: [DisposalHazard]
    let captureIssue: CaptureIssue
    let confidence: Int
}

nonisolated enum ObservationPolicyEngine {
    static func decision(from observation: WasteObservation) -> MultimodalDisposalDecision {
        let resolvedRoute = route(for: observation)
        let category = resolvedRoute.legacyCategory
        let basis = basis(for: observation, route: resolvedRoute)
        let parts = observation.parts.prefix(4).compactMap { part -> DisposalPartDecision? in
            let partRoute = route(material: part.material, form: part.packageForm, transparency: .unknown, contamination: .unknown)
            let partCategory = partRoute.legacyCategory
            guard partCategory != .unknown else { return nil }
            return DisposalPartDecision(component: String(part.name.prefix(16)), category: partCategory)
        }

        return MultimodalDisposalDecision(
            route: resolvedRoute,
            objectName: String((observation.objectCandidates.first ?? "").prefix(40)),
            confidence: max(0, min(100, observation.confidence)),
            basis: basis,
            visibleMark: String(observation.visibleMark.prefix(30)),
            alternatives: alternatives(for: category),
            captureIssue: observation.captureIssue,
            parts: parts,
            hazards: Array(observation.hazards.prefix(4)),
            nephronEligibility: nephronEligibility(for: observation, route: resolvedRoute)
        )
    }

    static func route(for observation: WasteObservation) -> DisposalRoute {
        if observation.hazards.contains(.pressurizedContainer)
            || observation.hazards.contains(.flammableResidue)
            || observation.hazards.contains(.chemicalResidue)
            || observation.hazards.contains(.damagedBattery) {
            return .householdHazardousWaste
        }

        if observation.hazards.contains(.brokenGlass) || observation.hazards.contains(.sharpObject) {
            return .specialWasteBag
        }

        if observation.captureIssue == .multipleObjects
            || observation.captureIssue == .blurred
            || observation.captureIssue == .tooFar
            || observation.captureIssue == .cropped {
            return .unknown
        }

        let material = observation.materialCandidates.first ?? .unknown
        return route(
            material: material,
            form: observation.packageForm,
            transparency: observation.transparency,
            contamination: observation.contamination
        )
    }

    private static func route(
        material: ObservedMaterial,
        form: PackageForm,
        transparency: Transparency,
        contamination: ContaminationLevel
    ) -> DisposalRoute {
        if contamination == .severe {
            return form == .nonRecyclableItem ? .volumeRateBag : .municipalCheck
        }

        switch form {
        case .beverageBottle:
            if material == .pet && transparency == .clear {
                return .recyclable(.clearPETBottle)
            }
            if material == .pet || material == .plastic {
                return .recyclable(.plasticContainerTray)
            }
        case .rigidContainerTray:
            if material == .pet || material == .plastic {
                return .recyclable(.plasticContainerTray)
            }
        case .flexibleFilmPouch:
            if material == .vinyl || material == .plastic {
                return .recyclable(.vinylPackaging)
            }
        case .paperItem:
            if material == .paper { return .recyclable(.paper) }
        case .liquidCarton:
            return .recyclable(.paperPack)
        case .beverageCan, .foodCan:
            if material == .metal { return .recyclable(.metalCan) }
        case .glassBottle:
            if material == .glass { return .recyclable(.glassBottle) }
        case .foamPackaging:
            if material == .foam { return .recyclable(.foamPackaging) }
        case .metalCookware:
            if material == .metal { return .recyclable(.metalScrap) }
        case .battery:
            return .batteryCollection
        case .smallElectronics:
            return .electronicsCollection
        case .lighting:
            return .lightingCollection
        case .clothing:
            return .clothingCollection
        case .foodScrap:
            return .foodWaste
        case .nonRecyclableItem:
            return .volumeRateBag
        case .unknown:
            break
        }

        return .unknown
    }

    private static func basis(for observation: WasteObservation, route: DisposalRoute) -> MultimodalEvidenceBasis {
        if !observation.hazards.isEmpty { return .safetyHazard }
        if route == .unknown { return .insufficient }
        if !observation.visibleMark.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .explicitMark }
        if observation.contamination == .severe { return .contamination }
        if observation.materialCandidates.contains(.mixed) { return .composite }
        if observation.packageForm == .nonRecyclableItem { return .nonRecyclableItem }
        if observation.packageForm != .unknown && observation.materialCandidates.first != .unknown { return .materialAndShape }
        if observation.materialCandidates.first != .unknown { return .materialOnly }
        if observation.packageForm != .unknown { return .shapeOnly }
        return .insufficient
    }

    private static func alternatives(for category: DisposalCategory) -> [DisposalCategory] {
        switch category {
        case .pet: [.plastic, .can, .glass]
        case .plastic: [.vinyl, .pet, .general]
        case .vinyl: [.plastic, .general, .paper]
        case .paper: [.paperPack, .general, .plastic]
        case .paperPack: [.paper, .plastic, .general]
        case .can: [.pet, .glass, .general]
        case .glass: [.can, .general, .plastic]
        case .styrofoam: [.plastic, .general, .paper]
        case .general, .unknown: [.plastic, .vinyl, .paper]
        }
    }

    private static func nephronEligibility(
        for observation: WasteObservation,
        route: DisposalRoute
    ) -> NephronEligibility {
        switch (route, observation.packageForm) {
        case (.recyclable(.clearPETBottle), .beverageBottle):
            return .likelyEligible
        case (.recyclable(.metalCan), .beverageCan):
            return .checkMachine
        case (.recyclable(.metalCan), .foodCan):
            return .notEligible
        default:
            return .notEligible
        }
    }
}
