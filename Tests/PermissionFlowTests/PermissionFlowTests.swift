import Foundation
import Testing
@testable import PermissionFlow
@testable import SystemSettingsKit

@Test
func paneURLsUseSecuritySettingsDeepLink() {
    #expect(
        PermissionFlowPane.fullDiskAccess.settingsURL.absoluteString ==
        "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles"
    )
}

@Test
func typedDisplaysAnchorBuildsDeepLink() {
    #expect(
        SystemSettingsDestination.displays(anchor: .resolutionSection).url.absoluteString ==
        "x-apple.systempreferences:com.apple.Displays-Settings.extension?resolutionSection"
    )
}

@Test
func typedLoginItemsAnchorBuildsDeepLink() {
    #expect(
        SystemSettingsDestination.loginItems(anchor: .extensionItems).url.absoluteString ==
        "x-apple.systempreferences:com.apple.LoginItems-Settings.extension?ExtensionItems"
    )
    #expect(
        SystemSettingsDestination.loginItems(anchor: .startupItemsPref).url.absoluteString ==
        "x-apple.systempreferences:com.apple.LoginItems-Settings.extension?startupItemsPref"
    )
}

@Test
func typedWiFiAnchorBuildsDeepLink() {
    #expect(
        SystemSettingsDestination.wifi.url.absoluteString ==
        "x-apple.systempreferences:com.apple.wifi-settings-extension"
    )
    #expect(
        SystemSettingsDestination.wifi(anchor: .advanced).url.absoluteString ==
        "x-apple.systempreferences:com.apple.wifi-settings-extension?Advanced"
    )
    #expect(
        SystemSettingsDestination.wifi(anchor: .generalDetails).url.absoluteString ==
        "x-apple.systempreferences:com.apple.wifi-settings-extension?General_Details"
    )
    #expect(
        SystemSettingsDestination.wifi(anchor: .generalJoin).url.absoluteString ==
        "x-apple.systempreferences:com.apple.wifi-settings-extension?General_Join"
    )
    #expect(
        SystemSettingsDestination.wifi(anchor: .generalMain).url.absoluteString ==
        "x-apple.systempreferences:com.apple.wifi-settings-extension?General_Main"
    )
}

@Test
@MainActor
func controllerAcceptsOnlyUniqueAppBundles() {
    let controller = PermissionFlowController()
    let appURL = URL(fileURLWithPath: "/Applications/Test.app")

    controller.registerDroppedApp(appURL)
    controller.registerDroppedApp(appURL)
    controller.registerDroppedApp(URL(fileURLWithPath: "/tmp/not-an-app.txt"))

    #expect(controller.droppedApps == [appURL])
}
