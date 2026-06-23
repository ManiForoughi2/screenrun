import Foundation

// shared across the app, widget, and monitor extension
enum AppGroup {
    static let id = "group.com.manif.runs"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }
}

enum StoreKey {
    static let limits = "runs.limits.v1"
    static let dayState = "runs.dayState.v1"
    static let activeRun = "runs.activeRun.v1"
    static let onboarded = "runs.onboarded.v1"
    static let themeMode = "runs.themeMode.v1"
    static let runMode = "runs.runMode.v1"
    static let sharedRuns = "runs.sharedRuns.v1"
    static let sharedUsed = "runs.sharedUsed.v1"
    static let completedRuns = "runs.completedRuns.v1"
    static let reviewAsked = "runs.reviewAsked.v1"
    static let lockUntil = "runs.lockUntil.v1"         // epoch; 0 = unlocked

    // written by the shield action extension on START A RUN tap, read + cleared
    // by the app on foreground since the shield process cant launch us itself
    static let shieldIntentToken = "runs.shieldIntent.tokenData.v1"
    static let shieldIntentAt = "runs.shieldIntent.at.v1"
}
