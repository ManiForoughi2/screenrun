import SwiftUI
import ManagedSettings

struct ActiveRunView: View {
    @EnvironmentObject var engine: RunEngine
    @EnvironmentObject var store: RunStore
    let run: ActiveRun

    @State private var now = Date()
    private let tick = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    private var remaining: TimeInterval { max(0, run.endsAt.timeIntervalSince(now)) }

    private var token: ApplicationToken? {
        store.limits.first { $0.id == run.limitID }?.token
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("RUNNING")
                .font(Theme.mono(12, .bold))
                .tracking(4)
                .foregroundStyle(Theme.dim)

            Group {
                if let token {
                    // Label(token) renders Apples real icon + name
                    Label(token)
                        .labelStyle(.titleAndIcon)
                        .font(Theme.mono(26, .bold))
                } else {
                    Text(run.label).font(Theme.mono(26, .bold))
                }
            }
            .foregroundStyle(Theme.fg)
            .padding(.top, 6)

            Text(clock(remaining))
                .font(Theme.mono(76, .bold))
                .monospacedDigit()
                .foregroundStyle(Theme.fg)
                .padding(.top, 24)
                .contentTransition(.numericText())

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Theme.faint)
                    Rectangle()
                        .fill(Theme.fg)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 40)
            .padding(.top, 28)

            Text("the app is open. when this hits zero it locks again.")
                .font(Theme.mono(12))
                .foregroundStyle(Theme.dim)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                engine.endRunNow()
            } label: {
                Text("END RUN NOW")
            }
            .buttonStyle(OutlineButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .screenBackground()
        .onReceive(tick) { t in
            now = t
            if remaining <= 0 {
                engine.endRunNow()
            }
        }
    }

    private var progress: CGFloat {
        let total = run.endsAt.timeIntervalSince(run.startedAt)
        guard total > 0 else { return 0 }
        return CGFloat(remaining / total)
    }

    private func clock(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        return String(format: "%01d:%02d", s / 60, s % 60)
    }
}
