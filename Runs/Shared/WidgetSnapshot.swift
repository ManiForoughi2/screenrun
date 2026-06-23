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

    // widgets only render in shared-pool mode; per-app has no single number to show
    var isPooled: Bool = true
    var poolLeft: Int = 0       // runs remaining in the shared pool
    var poolTotal: Int = 0      // pool size

    static let empty = WidgetSnapshot(items: [], activeLabel: nil, activeEndsAt: nil,
                                      isPooled: true, poolLeft: 0, poolTotal: 0)
}

extension StoreKey {
    static let widgetSnapshot = "runs.widgetSnapshot.v1"
}
