import ManagedSettings
import Foundation

// background process, CANNOT open URLs or launch apps (response is only
// .none/.close/.defer), so START A RUN records intent in the App Group and
// closes; Runs reads it on next launch and starts the run for that app
final class ShieldActionExtension: ShieldActionDelegate {

    // must match StoreKey in the main app, Runs reads and clears this on launch
    private static let groupID = "group.com.manif.runs"
    private static let kPendingToken = "runs.shieldIntent.tokenData.v1"
    private static let kPendingAt = "runs.shieldIntent.at.v1"

    override func handle(action: ShieldAction,
                         for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            recordIntent(for: application)
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction,
                         for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.close)
    }

    override func handle(action: ShieldAction,
                         for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.close)
    }

    private func recordIntent(for token: ApplicationToken) {
        let defaults = UserDefaults(suiteName: Self.groupID)
        guard let data = try? JSONEncoder().encode(token) else { return }
        defaults?.set(data, forKey: Self.kPendingToken)
        defaults?.set(Date().timeIntervalSince1970, forKey: Self.kPendingAt)
    }
}
