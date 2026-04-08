import Observation
import SwiftUI

struct RootView: View {
    @Bindable var model: AppModel

    var body: some View {
        ZStack(alignment: .top) {
            // Persistent dark base prevents white flash during any transition
            Color.bgBase.ignoresSafeArea()

            Group {
                if model.session.hasCompletedOnboarding {
                    MainShellView(model: model)
                } else if model.splashHasPlayed {
                    OnboardingFlowView(model: model)
                        .transition(.move(edge: .trailing))
                } else {
                    SplashScreenView {
                        model.splashHasPlayed = true
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.45), value: model.splashHasPlayed)

            if let banner = model.statusBanner {
                Text(banner)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.85), in: Capsule())
                    .padding(.top, 16)
                    .onTapGesture {
                        model.dismissBanner()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: model.statusBanner != nil)
    }
}

