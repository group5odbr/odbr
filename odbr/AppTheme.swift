import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.969, green: 0.980, blue: 0.953)
    static let card = Color.white
    static let mintSurface = Color(red: 0.918, green: 0.965, blue: 0.929)
    static let yellowSurface = Color(red: 1.000, green: 0.961, blue: 0.843)
    static let primaryText = Color(red: 0.090, green: 0.129, blue: 0.106)
    static let secondaryText = Color(red: 0.400, green: 0.451, blue: 0.420)
    static let border = Color(red: 0.898, green: 0.929, blue: 0.894)
    static let accent = Color(red: 0.086, green: 0.655, blue: 0.396)
    static let deepGreen = Color(red: 0.031, green: 0.447, blue: 0.278)
    static let warning = Color(red: 0.761, green: 0.478, blue: 0.000)
    static let error = Color(red: 0.851, green: 0.294, blue: 0.294)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 18
        static let large: CGFloat = 24
        static let scan: CGFloat = 32
    }
}

struct UtilityCardModifier: ViewModifier {
    var highlighted = false

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.lg)
            .background(highlighted ? AppTheme.mintSurface : AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
    }
}

extension View {
    func utilityCard(highlighted: Bool = false) -> some View {
        modifier(UtilityCardModifier(highlighted: highlighted))
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(AppTheme.deepGreen)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.mintSurface.opacity(configuration.isPressed ? 0.65 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
    }
}

struct IconTile: View {
    let systemName: String
    var tint = AppTheme.accent
    var background = AppTheme.mintSurface

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
    }
}
