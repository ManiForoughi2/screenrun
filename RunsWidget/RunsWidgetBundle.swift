import WidgetKit
import SwiftUI

@main
struct RunsWidgetBundle: WidgetBundle {
    var body: some Widget {
        RunLiveActivity()
        RunDotsWidget()    // dots-only, listed before the number variant
        RunHomeWidget()
    }
}
