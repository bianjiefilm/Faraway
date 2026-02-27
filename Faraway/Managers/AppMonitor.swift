import Foundation
import AppKit
import Combine

/// Monitoring mode selection
enum MonitoringMode: String, CaseIterable {
    case global = "全局"
    case selectApps = "手动选择"

    var description: String {
        switch self {
        case .global:
            return "无论是否打开软件，定时提醒护眼"
        case .selectApps:
            return "从正在运行的 App 中选择要监测的软件"
        }
    }
}

/// Monitors running applications to detect video editing software
class AppMonitor: ObservableObject {
    static let shared = AppMonitor()

    @Published var isEditingAppActive = false
    @Published var currentEditingApp: String?

    /// Monitoring mode: global or selectApps
    @Published var monitoringMode: MonitoringMode = .global {
        didSet {
            UserDefaults.standard.set(monitoringMode.rawValue, forKey: "EyeBreak_MonitoringMode")
            checkRunningApps()
        }
    }

    /// Selected apps for selectApps mode (bundle IDs)
    @Published var selectedApps: Set<String> = [] {
        didSet {
            UserDefaults.standard.set(Array(selectedApps), forKey: "EyeBreak_SelectedApps")
            checkRunningApps()
        }
    }

    /// All currently running applications (for selection in selectApps mode)
    @Published var runningApplications: [(bundleId: String, name: String)] = []

    private var timer: Timer?
    private var workspaceObserver: Any?

    /// All available video editing apps (built-in + custom)
    var allAvailableApps: [String: String] {
        monitoredApps.merging(customApps) { current, _ in current }
    }

    /// Bundle identifiers of video editing apps to monitor
    private let monitoredApps: [String: String] = [
        "com.lemon.lvpro": "剪映专业版",
        "com.apple.FinalCut": "Final Cut Pro",
        "com.blackmagic-design.DaVinciResolve": "DaVinci Resolve",
        "com.blackmagic-design.DaVinciResolve.ProjectServer": "DaVinci Resolve",
        "com.adobe.PremierePro": "Premiere Pro",
        "com.adobe.premiererush": "Premiere Rush",
        // Additional common editing apps
        "com.apple.iMovieApp": "iMovie",
        "org.perian.Perian": "Perian",
    ]

    /// User can add custom bundle IDs
    @Published var customApps: [String: String] = [:] {
        didSet {
            saveCustomApps()
        }
    }

    private init() {
        loadSettings()
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        // Load monitoring mode
        if let modeString = UserDefaults.standard.string(forKey: "EyeBreak_MonitoringMode"),
           let mode = MonitoringMode(rawValue: modeString) {
            monitoringMode = mode
        }

        // Load selected apps
        if let saved = UserDefaults.standard.array(forKey: "EyeBreak_SelectedApps") as? [String] {
            selectedApps = Set(saved)
        }

        // Load custom apps
        if let saved = UserDefaults.standard.dictionary(forKey: "EyeBreak_CustomApps") as? [String: String] {
            customApps = saved
        }
    }

    // MARK: - Monitoring

    func startMonitoring() {
        // Poll every 3 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.checkRunningApps()
        }
        timer?.tolerance = 1.0
        RunLoop.current.add(timer!, forMode: .common)

        // Also observe app activation changes
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.checkRunningApps()
        }

        // Initial check
        checkRunningApps()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    /// Manually refresh running apps list (public for external calls)
    func refreshRunningApps() {
        // Synchronously update the running apps list
        let runningApps = NSWorkspace.shared.runningApplications

        // Update running applications list for selection
        var runningList: [(bundleId: String, name: String)] = []
        for app in runningApps {
            guard let bundleId = app.bundleIdentifier,
                  let name = app.localizedName,
                  !app.isTerminated,
                  app.activationPolicy == .regular else { continue }
            runningList.append((bundleId: bundleId, name: name))
        }
        // Sort by name
        runningList.sort { $0.name < $1.name }

        self.runningApplications = runningList

        // Also check for active editing apps
        checkRunningApps()
    }

    private func checkRunningApps() {
        let runningApps = NSWorkspace.shared.runningApplications

        // Update running applications list for selection
        var runningList: [(bundleId: String, name: String)] = []
        for app in runningApps {
            guard let bundleId = app.bundleIdentifier,
                  let name = app.localizedName,
                  !app.isTerminated,
                  app.activationPolicy == .regular else { continue }
            runningList.append((bundleId: bundleId, name: name))
        }
        // Sort by name
        runningList.sort { $0.name < $1.name }

        DispatchQueue.main.async { [weak self] in
            self?.runningApplications = runningList
        }

        // Determine which apps to check based on mode
        var appsToCheck: [String: String] = [:]
        switch monitoringMode {
        case .global:
            // In global mode, always consider active only if timer should run
            // We'll check if any app is running to show appropriate UI
            break
        case .selectApps:
            // Add all selected apps to check - both known apps and custom apps
            for bundleId in selectedApps {
                // First check if it's a known app
                if let name = allAvailableApps[bundleId] {
                    appsToCheck[bundleId] = name
                } else {
                    // For custom apps, try to find the name from running apps
                    if let runningApp = runningList.first(where: { $0.bundleId == bundleId }) {
                        appsToCheck[bundleId] = runningApp.name
                    }
                }
            }
        }

        var found = false
        var foundName: String?

        // Check selected apps in selectApps mode
        if monitoringMode == .selectApps {
            for app in runningApps {
                guard let bundleId = app.bundleIdentifier else { continue }
                if let name = appsToCheck[bundleId] {
                    if !app.isTerminated {
                        found = true
                        foundName = name
                        break
                    }
                }
            }
        }
        // In global mode, always consider active (timer runs regardless)
        if monitoringMode == .global {
            found = true
            foundName = "全局守护"
        }

        DispatchQueue.main.async { [weak self] in
            if self?.isEditingAppActive != found {
                self?.isEditingAppActive = found
            }
            if self?.currentEditingApp != foundName {
                self?.currentEditingApp = foundName
            }
        }
    }

    // MARK: - Custom Apps Persistence

    private func saveCustomApps() {
        UserDefaults.standard.set(customApps, forKey: "EyeBreak_CustomApps")
    }

    private func loadCustomApps() {
        if let saved = UserDefaults.standard.dictionary(forKey: "EyeBreak_CustomApps") as? [String: String] {
            customApps = saved
        }
    }

    func addCustomApp(bundleId: String, name: String) {
        customApps[bundleId] = name
    }

    func removeCustomApp(bundleId: String) {
        customApps.removeValue(forKey: bundleId)
    }

    /// Get display name for an app (from known apps or fallback to localized name)
    func displayName(for bundleId: String) -> String {
        return allAvailableApps[bundleId] ?? bundleId
    }
}
