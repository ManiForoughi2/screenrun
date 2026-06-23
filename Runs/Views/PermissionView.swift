import SwiftUI

struct PermissionView: View {
    @EnvironmentObject var engine: RunEngine
    @State private var requesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 18) {
                Text("RUNS")
                    .font(Theme.mono(34, .bold))
                    .tracking(4)
                    .foregroundStyle(Theme.fg)

                Text("a few short runs a day.\nthat's all the social media you get.")
                    .font(Theme.mono(14))
                    .foregroundStyle(Theme.dim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            VStack(spacing: 14) {
                if let err = engine.authError {
                    Text(err)
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.dim)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        requesting = true
                        await engine.requestAuthorization()
                        requesting = false
                    }
                } label: {
                    Text(requesting ? "..." : "ALLOW SCREEN TIME")
                }
                .buttonStyle(OutlineButtonStyle(filled: true))
                .disabled(requesting)

                Text("required to block apps when your time is up.")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.dim)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .screenBackground()
    }
}
