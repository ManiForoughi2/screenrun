import SwiftUI

@main
struct RunsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var engine = RunEngine.shared
    @StateObject private var store = RunStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(engine)
                .environmentObject(store)
                .preferredColorScheme(store.themeMode.colorScheme)
                .onAppear {
                    engine.refreshAuthorization()
                    // pending shield START A RUN tap waiting from another process
                    engine.consumeShieldIntent()
                    engine.reapplyBaselineShield()
                }
                .onOpenURL { url in
                    engine.handle(url: url)
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                engine.store.rolloverIfNeeded()
                engine.store.expireLockIfNeeded()
                engine.refreshAuthorization()
                engine.consumeShieldIntent()
                engine.reapplyBaselineShield()   // also ends expired runs
            }
        }
    }
}
