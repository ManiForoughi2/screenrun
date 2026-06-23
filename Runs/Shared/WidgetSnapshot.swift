import Foundation

// token-free mirror of run state, the widget process cant resolve
// ApplicationTokens or touch ManagedSettings so it renders from this
struct WidgetSnapshot: Codable {
    struct Item: Codable, Identifiable {
        var id: UUID            // limit.id, also the deep-link target
        var label: String       // user-set name, Apple masks the real one
        var minutesPerRun: Int
        var runsLeft: Int
        var runsTotal: Int
    }

    var items: [Item]
    var activeLabel: String?    // set while a run is live
    var activeEndsAt: Date?

    static let empty = WidgetSnapshot(items: [], activeLabel: nil, activeEndsAt: nil)
}

extension StoreKey {
    static let widgetSnapshot = "runs.widgetSnapshot.v1"
}
