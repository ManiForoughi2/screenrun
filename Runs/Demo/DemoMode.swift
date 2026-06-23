import SwiftUI

// screenshot/demo mode, gated behind a launch arg so it never ships.
// real app rows use Apple's Label(token); these mock rows stand in for the
// store so we can render populated screens without Family Controls.
enum DemoMode {
    static var isOn: Bool {
        ProcessInfo.processInfo.arguments.contains("--demo")
    }

    static var screen: String {
        for a in ProcessInfo.processInfo.arguments {
            if a.hasPrefix("--screen=") { return String(a.dropFirst("--screen=".count)) }
        }
        return "home"
    }
}

struct DemoApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let symbol: String
    let color: Color
    let minutesPerRun: Int
    let runsLeft: Int
    let runsTotal: Int
}

extension DemoApp {
    // generic app categories, not real brands, to stay clear of trademark issues.
    // monochrome tiles to keep the black/white identity.
    static let sample: [DemoApp] = [
        DemoApp(name: "Social", symbol: "bubble.left.fill", color: .white,
                minutesPerRun: 3, runsLeft: 2, runsTotal: 4),
        DemoApp(name: "Videos", symbol: "play.rectangle.fill", color: .white,
                minutesPerRun: 15, runsLeft: 1, runsTotal: 2),
        DemoApp(name: "Feed", symbol: "square.stack.fill", color: .white,
                minutesPerRun: 3, runsLeft: 3, runsTotal: 4),
        DemoApp(name: "Messages", symbol: "ellipsis.message.fill", color: .white,
                minutesPerRun: 2, runsLeft: 1, runsTotal: 4)
    ]
}
