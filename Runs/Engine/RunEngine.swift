import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings
import ActivityKit
import Combine

@MainActor
final class RunEngine: ObservableObject {
    static let shared = RunEngine()

    let store = RunStore.shared
    private let shield = ShieldController()
    private let center = DeviceActivityCenter()

    @Published var authorized = false
    @Published var authError: String?

    static let runActivityName = DeviceActivityName("runs.activeRun")
    static let dailyActivityName = DeviceActivityName("runs.daily")
    // watched by the monitor extension to know the run is over
    static let runEndEvent = DeviceActivityEvent.Name("runs.runEnded")

    private var liveActivity: Activity<RunActivityAttributes>?

    private init() {}

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorized = AuthorizationCenter.shared.authorizationStatus == .approved
            authError = nil
        } catch {
            authorized = false
            authError = error.localizedDescription
        }
    }

    func refreshAuthorization() {
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    // call on launch / whenever limits change
    func reapplyBaselineShield() {
        store.rolloverIfNeeded()
        endRunIfExpired()

        let all = Set(store.limits.map(\.token))
        let openToken: ApplicationToken? = store.activeRun.flatMap { run in
            store.limits.first { $0.id == run.limitID }?.token
        }
        shield.applyShield(allTokens: all, except: openToken)
        scheduleDailyReset()
    }

    // midnight repeating window, intervalDidEnd tells the monitor extension to
    // wipe the run counters for the new day
    private func scheduleDailyReset() {
        guard !store.limits.isEmpty else {
            center.stopMonitoring([Self.dailyActivityName])
            return
        }
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        do {
            try center.startMonitoring(Self.dailyActivityName, during: schedule)
        } catch {
            // non-fatal, app also resets on foreground via rolloverIfNeeded
        }
    }

    // widget tiles deep-link in as screenrun://run/<limitID> since the widget
    // process cant start a run itself, we start it here once foregrounded
    func handle(url: URL) {
        guard url.scheme == "screenrun", url.host == "run" else { return }

        let idString = url.lastPathComponent
        guard let id = UUID(uuidString: idString),
              let limit = store.limits.first(where: { $0.id == id })
        else { return }

        // reconcile day/expiry first so runsLeft is accurate
        store.rolloverIfNeeded()
        endRunIfExpired()
        if store.canStartRun(for: limit) {
            startRun(for: limit)
        }
    }

    // shield action extension cant launch us (iOS forbids it) so on START A RUN
    // tap it stashes the token in the app group, we pick it up next foreground.
    // one-shot and short TTL so a stale tap doesnt silently burn a run
    private static let shieldIntentTTL: TimeInterval = 60

    func consumeShieldIntent() {
        let defaults = AppGroup.defaults
        guard let data = defaults.data(forKey: StoreKey.shieldIntentToken) else { return }
        let at = defaults.double(forKey: StoreKey.shieldIntentAt)

        // always clear so it cant fire twice, even if we dont act on it
        defaults.removeObject(forKey: StoreKey.shieldIntentToken)
        defaults.removeObject(forKey: StoreKey.shieldIntentAt)

        guard at > 0, Date().timeIntervalSince1970 - at <= Self.shieldIntentTTL else { return }
        guard let token = try? JSONDecoder().decode(ApplicationToken.self, from: data),
              let limit = store.limits.first(where: { $0.token == token })
        else { return }

        store.rolloverIfNeeded()
        endRunIfExpired()
        if store.canStartRun(for: limit) {
            startRun(for: limit)
        }
    }

    func startRun(for limit: LimitConfig) {
        guard store.canStartRun(for: limit) else { return }

        let run = store.beginRun(for: limit)

        let all = Set(store.limits.map(\.token))
        shield.applyShield(allTokens: all, except: limit.token)

        scheduleRunEnd(for: limit)
        startLiveActivity(for: limit, run: run)
    }

    func endRunNow() {
        guard store.activeRun != nil else { return }
        store.endRun()
        store.recordCompletedRun()
        center.stopMonitoring([Self.runActivityName])
        let all = Set(store.limits.map(\.token))
        shield.applyShield(allTokens: all, except: nil)
        Task { await endLiveActivity() }
    }

    // foregrounded after the timer already passed
    func endRunIfExpired() {
        if let run = store.activeRun, Date() >= run.endsAt {
            store.endRun()
            store.recordCompletedRun()
            let all = Set(store.limits.map(\.token))
            shield.applyShield(allTokens: all, except: nil)
            Task { await endLiveActivity() }
        }
    }

    // event threshold fires eventDidReachThreshold in the monitor extension even
    // while Runs is backgrounded/killed, re-shields once minutesPerRun is spent.
    // DeviceActivitySchedule interval must be >= 15 min so we cant use
    // intervalDidEnd for short runs, the threshold has no such floor; schedule is
    // a long outer window the event lives inside
    private func scheduleRunEnd(for limit: LimitConfig) {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: false
        )

        let event = DeviceActivityEvent(
            applications: [limit.token],
            threshold: DateComponents(minute: limit.minutesPerRun)
        )

        do {
            try center.startMonitoring(
                Self.runActivityName,
                during: schedule,
                events: [Self.runEndEvent: event]
            )
        } catch {
            // best-effort, in-app timer + foreground reconciliation still reblock
            print("device activity start failed: \(error)")
        }
    }

    private func startLiveActivity(for limit: LimitConfig, run: ActiveRun) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let liveLabel = limit.label.isEmpty ? "Run" : limit.label
        let attrs = RunActivityAttributes(
            appLabel: liveLabel,
            runsLeftAfter: store.runsLeft(for: limit)
        )
        let state = RunActivityAttributes.ContentState(endsAt: run.endsAt, startedAt: run.startedAt)
        do {
            liveActivity = try Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: run.endsAt),
                pushType: nil
            )
        } catch {
            print("live activity start failed: \(error)")
        }
    }

    private func endLiveActivity() async {
        let final = RunActivityAttributes.ContentState(endsAt: Date(), startedAt: Date())
        for activity in Activity<RunActivityAttributes>.activities {
            await activity.end(.init(state: final, staleDate: nil), dismissalPolicy: .immediate)
        }
        liveActivity = nil
    }
}
