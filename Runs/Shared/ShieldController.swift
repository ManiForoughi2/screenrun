import Foundation
import ManagedSettings
import FamilyControls

// every configured app is shielded except the one with an active run
struct ShieldController {
    // named store so the monitor extension addresses the exact same shield
    static let storeName = ManagedSettingsStore.Name("runs.main")
    private let store = ManagedSettingsStore(named: storeName)

    func applyShield(allTokens: Set<ApplicationToken>, except open: ApplicationToken? = nil) {
        var blocked = allTokens
        if let open { blocked.remove(open) }

        if blocked.isEmpty {
            store.shield.applications = nil
        } else {
            store.shield.applications = blocked
        }
    }

    func clearAll() {
        store.shield.applications = nil
        store.clearAllSettings()
    }
}
