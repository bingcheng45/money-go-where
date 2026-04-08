import Lottie
import SwiftUI

struct SplashScreenView: View {
    let onComplete: () -> Void

    @State private var titleOpacity: Double = 0
    @State private var lottieOpacity: Double = 1
    @State private var tagline1Opacity: Double = 0
    @State private var tagline2Opacity: Double = 0

    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()

            // Lottie — full screen width, centered vertically
            LottieView {
                try await DotLottieFile.named("Flying_money")
            }
            .playing(loopMode: .playOnce)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(lottieOpacity)

            // Title — pinned to top
            VStack(spacing: 0) {
                Text("MoneyGoWhere")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 72)
                    .opacity(titleOpacity)
                Spacer()
            }

            // Taglines — vertically centered
            VStack(spacing: 6) {
                Text("Know where every dollar goes.")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(tagline1Opacity)

                Text("Before it's gone.")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.brandGreen)
                    .multilineTextAlignment(.center)
                    .opacity(tagline2Opacity)
            }
            .padding(.horizontal, 32)
        }
        .task { await runSequence() }
    }

    // MARK: - Animation Sequence

    private func runSequence() async {
        // 0s — lottie already visible and playing

        // 1s — title fades in
        try? await Task.sleep(for: .seconds(1))
        withAnimation(.easeInOut(duration: 0.5)) { titleOpacity = 1 }

        // 3.5s — lottie starts fading out (2.5s after the 1s mark)
        try? await Task.sleep(for: .seconds(2.5))
        withAnimation(.easeInOut(duration: 0.5)) { lottieOpacity = 0 }

        // 4.5s — lottie gone; tagline 1 fades in
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation(.easeInOut(duration: 0.5)) { tagline1Opacity = 1 }

        // 5.5s — tagline 2 fades in (1.5s after tagline 1 starts at 4s)
        try? await Task.sleep(for: .seconds(1.5))
        withAnimation(.easeInOut(duration: 0.5)) { tagline2Opacity = 1 }

        // 6.5s — all text fades out (1.5s after tagline2 animation fired at 5s,
        //         giving 0.5s for tagline2 to finish + 1s hold = 5.0 + 1.5 = 6.5s)
        try? await Task.sleep(for: .seconds(1.5))
        withAnimation(.easeInOut(duration: 0.4)) {
            titleOpacity = 0
            tagline1Opacity = 0
            tagline2Opacity = 0
        }

        // ~7s — hand off to onboarding
        try? await Task.sleep(for: .milliseconds(500))
        onComplete()
    }
}
