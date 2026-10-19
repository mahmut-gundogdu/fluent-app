import FluentCore

public extension AppController {
    static func live() -> AppController {
        AppController(
            settings: AppSettings(
                secretStore: KeychainSecretStore(),
                providerFactory: .live,
                launchAtLoginController: SMAppLaunchController()
            ),
            clipboardService: LiveClipboardService(),
            hotKeyManager: LiveHotKeyManager.shared
        )
    }
}
