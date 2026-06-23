import ManagedSettings
import ManagedSettingsUI
import UIKit

// custom block screen iOS shows for a shielded app. own process, cant import
// RunStore so it decodes the App Group state directly
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldState.resolve(for: application.token).configuration()
    }

    // we dont shield categories but the API requires this override
    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration {
        ShieldState.resolve(for: application.token).configuration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        ShieldState.blocked(label: nil).configuration()
    }

    override func configuration(shielding webDomain: WebDomain,
                                in category: ActivityCategory) -> ShieldConfiguration {
        ShieldState.blocked(label: nil).configuration()
    }
}
