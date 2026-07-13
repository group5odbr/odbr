import SwiftUI

extension DisposalCategory {
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
        case .paperPack:
            "takeoutbag.and.cup.and.straw.fill"
        case .can:
            "circle.fill"
        case .glass:
            "drop.triangle.fill"
        case .styrofoam:
            "shippingbox.and.arrow.backward.fill"
        case .general:
            "trash.fill"
        case .unknown:
            "questionmark.circle.fill"
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
        case .paperPack:
            Color(red: 0.482, green: 0.314, blue: 0.157)
        case .can:
            Color(red: 0.369, green: 0.435, blue: 0.502)
        case .glass:
            Color(red: 0.071, green: 0.514, blue: 0.561)
        case .styrofoam:
            Color(red: 0.408, green: 0.451, blue: 0.929)
        case .general, .unknown:
            AppTheme.warning
        }
    }
}
