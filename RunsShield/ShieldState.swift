import ManagedSettings
import ManagedSettingsUI
import UIKit

enum ShieldState {
    case outOfRuns(label: String?)
    case blocked(label: String?)

    // shield primitives are UIKit-only, no FairfaxHD or SwiftUI; match theme via color + wordmark
    private static let bg = UIColor.black
    private static let fg = UIColor.white
    private static let dim = UIColor(white: 1.0, alpha: 0.5)

    func configuration() -> ShieldConfiguration {
        let icon = UIImage(named: "ShieldGlyph")

        switch self {
        case .outOfRuns(let label):
            return ShieldConfiguration(
                backgroundBlurStyle: .dark,
                backgroundColor: Self.bg,
                icon: icon,
                title: ShieldConfiguration.Label(
                    text: Self.wordmark(label),
                    color: Self.fg
                ),
                subtitle: ShieldConfiguration.Label(
                    text: "out of runs for today.\nresets at midnight.",
                    color: Self.dim
                ),
                primaryButtonLabel: ShieldConfiguration.Label(
                    text: "OK",
                    color: Self.bg
                ),
                primaryButtonBackgroundColor: Self.fg
            )

        case .blocked(let label):
            return ShieldConfiguration(
                backgroundBlurStyle: .dark,
                backgroundColor: Self.bg,
                icon: icon,
                title: ShieldConfiguration.Label(
                    text: Self.wordmark(label),
                    color: Self.fg
                ),
                subtitle: ShieldConfiguration.Label(
                    text: "this app is resting.\nopen Runs to start a run.",
                    color: Self.dim
                ),
                // iOS wont let the extension launch Runs, so the button only stashes
                // intent + dismisses. labelled DISMISS so it doesnt promise a launch
                // it cant deliver; the subtitle is the real call to action.
                primaryButtonLabel: ShieldConfiguration.Label(
                    text: "DISMISS",
                    color: Self.bg
                ),
                primaryButtonBackgroundColor: Self.fg
            )
        }
    }

    private static func wordmark(_ label: String?) -> String {
        if let label, !label.isEmpty {
            return "RUNS\n\(label.uppercased())"
        }
        return "RUNS"
    }

    static func resolve(for token: ApplicationToken?) -> ShieldState {
        let store = ShieldStore()
        guard let token, let limit = store.limit(for: token) else {
            return .blocked(label: nil)
        }
        return store.runsLeft(for: limit) > 0
            ? .blocked(label: limit.label)
            : .outOfRuns(label: limit.label)
    }
}
