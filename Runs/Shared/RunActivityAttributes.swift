import Foundation
import ActivityKit

struct RunActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endsAt: Date
        var startedAt: Date
    }

    var appLabel: String
    var runsLeftAfter: Int        // runs remaining once this run ends
}
