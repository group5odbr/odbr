import SwiftUI
import UIKit

enum AppTheme {
    static let background = adaptive(light: rgb(247, 250, 243), dark: rgb(17, 20, 18))
    static let card = adaptive(light: rgb(255, 255, 255), dark: rgb(26, 31, 27))
    static let mintSurface = adaptive(light: rgb(234, 246, 237), dark: rgb(23, 51, 35))
    static let yellowSurface = adaptive(light: rgb(255, 245, 215), dark: rgb(59, 45, 11))
    static let primaryText = adaptive(light: rgb(23, 33, 27), dark: rgb(247, 250, 243))
    static let secondaryText = adaptive(light: rgb(102, 115, 107), dark: rgb(180, 189, 183))
    static let border = adaptive(light: rgb(229, 237, 228), dark: rgb(45, 53, 47))
    static let accent = adaptive(light: rgb(22, 167, 101), dark: rgb(73, 216, 142))
    static let deepGreen = adaptive(light: rgb(8, 114, 71), dark: rgb(150, 240, 191))
    static let warning = adaptive(light: rgb(194, 122, 0), dark: rgb(255, 202, 78))
    static let actionText = adaptive(light: rgb(255, 255, 255), dark: rgb(11, 27, 18))

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

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> UIColor {
        UIColor(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
    }
}

struct UtilityCardModifier: ViewModifier {
    var highlighted = false
    var warning = false

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.lg)
            .background(
                warning
                    ? AppTheme.yellowSurface
                    : (highlighted ? AppTheme.mintSurface : AppTheme.card)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(warning ? AppTheme.warning.opacity(0.35) : AppTheme.border, lineWidth: 1)
            }
    }
}

extension View {
    func utilityCard(highlighted: Bool = false, warning: Bool = false) -> some View {
        modifier(UtilityCardModifier(highlighted: highlighted, warning: warning))
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(AppTheme.actionText)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(
                AppTheme.deepGreen.opacity(
                    isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.45
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(AppTheme.deepGreen)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .frame(minHeight: 48)
            .background(AppTheme.mintSurface.opacity(configuration.isPressed ? 0.65 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
    }
}

struct ScreenHeader: View {
    let title: String
    let subtitle: String
    var onShowInformation: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                    .accessibilityAddTraits(.isHeader)

                Text(subtitle)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if let onShowInformation {
                Button(action: onShowInformation) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.deepGreen)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("설정 및 앱 정보")
                .accessibilityIdentifier("app.information")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    @ViewBuilder
    func tabScreenPadding() -> some View {
        if #available(iOS 26.0, *) {
            padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.xl)
                .padding(.bottom, 112)
        } else {
            padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xxl)
        }
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
            .accessibilityHidden(true)
    }
}
