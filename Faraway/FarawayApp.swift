import SwiftUI

@main
struct FarawayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We use Settings as a dummy scene since this is a menu bar only app
        Settings {
            EmptyView()
        }
    }
}
