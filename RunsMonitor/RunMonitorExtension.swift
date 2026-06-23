import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

// out-of-process, reblocks every configured app when a window ends even if the
// app was killed; also does the midnight daily reset
final class RunMonitorExtension: DeviceActivityMonitor {

    // store name and group id must match the main app
    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("runs.main"))
    private let defaults = UserDefaults(suiteName: "group.com.manif.runs")

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        if activity.rawValue == "runs.daily" {
            resetDailyCounters()
        }

        reblockAll()
        clearActiveRun()
    }

    // fires when minutesPerRun spent in-app, primary re-block path for a finished run
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                         activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        reblockAll()
        clearActiveRun()
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
    }

    private func reblockAll() {
        let tokens = configuredTokens()
        store.shield.applications = tokens.isEmpty ? nil : tokens
    }

    private func configuredTokens() -> Set<ApplicationToken> {
        guard let data = defaults?.data(forKey: "runs.limits.v1") else { return [] }
        guard let limits = try? JSONDecoder().decode([LimitConfigDTO].self, from: data) else { return [] }
        return Set(limits.map(\.token))
    }

    private func clearActiveRun() {
        defaults?.removeObject(forKey: "runs.activeRun.v1")
    }

    private func resetDailyCounters() {
        // write a fresh empty day, app reconciles exact date on next launch
        struct DayDTO: Encodable { let day: String; let runsUsed: [String: Int] }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        let dto = DayDTO(day: f.string(from: Date()), runsUsed: [:])
        if let data = try? JSONEncoder().encode(dto) {
            defaults?.set(data, forKey: "runs.dayState.v1")
        }
    }
}

// minimal mirror of LimitConfig, only the token is needed here
private struct LimitConfigDTO: Decodable {
    let token: ApplicationToken
}
