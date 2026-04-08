import SwiftUI

// MARK: - Colour Tokens

extension Color {
    static let bgBase           = Color(red: 0.102, green: 0.102, blue: 0.122) // #1A1A1F
    static let bgSurface        = Color(red: 0.145, green: 0.145, blue: 0.157) // #252528
    static let bgSurfaceRaised  = Color(red: 0.180, green: 0.180, blue: 0.200) // #2E2E33
    static let brandGreen       = Color(red: 0.345, green: 0.800, blue: 0.008) // #58CC02
    static let brandGreenDark   = Color(red: 0.275, green: 0.639, blue: 0.008) // #46A302
    static let accentBlue       = Color(red: 0.110, green: 0.690, blue: 0.965) // #1CB0F6
    static let accentOrange     = Color(red: 1.000, green: 0.588, blue: 0.000) // #FF9600
    static let accentPurple     = Color(red: 0.482, green: 0.361, blue: 0.961) // #7B5CF5
    static let accentPurpleDeep = Color(red: 0.294, green: 0.176, blue: 0.624) // #4B2D9F
    static let textSecondary    = Color(red: 0.686, green: 0.686, blue: 0.686) // #AFAFAF
    static let separatorDark    = Color(red: 0.180, green: 0.180, blue: 0.200) // #2E2E33
    static let destructiveRed   = Color(red: 1.000, green: 0.294, blue: 0.294) // #FF4B4B
}

// MARK: - BrandPrimaryButton Modifier

struct BrandPrimaryButton: ViewModifier {
    var isPaywall: Bool = false
    var isDisabled: Bool = false

    func body(content: Content) -> some View {
        content
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(isPaywall ? Color.bgBase : Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isPaywall ? Color.white : Color.brandGreen,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .opacity(isDisabled ? 0.4 : 1)
    }
}

// MARK: - BrandPrimaryButtonStyle

struct BrandPrimaryButtonStyle: ButtonStyle {
    var isPaywall: Bool = false
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let pressing = configuration.isPressed && !isDisabled
        configuration.label
            .scaleEffect(pressing ? 0.97 : 1.0)
            .shadow(
                color: Color.brandGreenDark.opacity((isPaywall || isDisabled || pressing) ? 0 : 1),
                radius: 0, x: 0, y: pressing ? 0 : 4
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressing)
    }
}

extension View {
    func brandPrimaryButton(isPaywall: Bool = false, isDisabled: Bool = false) -> some View {
        modifier(BrandPrimaryButton(isPaywall: isPaywall, isDisabled: isDisabled))
    }
}

// MARK: - AuthButtonStyle (scale-only, no shadow)

struct AuthButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
