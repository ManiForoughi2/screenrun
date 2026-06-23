import SwiftUI

struct RootView: View {
    @EnvironmentObject var engine: RunEngine
    @EnvironmentObject var store: RunStore

    var body: some View {
        Group {
            if DemoMode.isOn {
                demoScreen
            } else if !store.onboarded {
                OnboardingView { }
            } else if !engine.authorized {
                PermissionView()
            } else {
                HomeView()
            }
        }
        .screenBackground()
        .animation(.easeInOut(duration: 0.25), value: store.onboarded)
        .animation(.easeInOut(duration: 0.25), value: engine.authorized)
    }

    @ViewBuilder
    private var demoScreen: some View {
        switch DemoMode.screen {
        case "home": DemoHomeView()
        case "run": DemoActiveRunView()
        case "lock": LockSettingsDemo()
        case "blocked": DemoBlockedView()
        default: DemoHomeView()
        }
    }
}
