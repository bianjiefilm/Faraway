import SwiftUI
import Combine
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var overlayWindow: NSWindow?
    var summaryWindow: NSWindow?

    let appMonitor = AppMonitor.shared
    let timerManager = TimerManager.shared
    let sessionTracker = SessionTracker.shared

    private var cancellables = Set<AnyCancellable>()
    private let firstLaunchKey = "Faraway_FirstLaunch"

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Record app launch time
        appLaunchDate = Date()

        // Hide dock icon - menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Check if first launch - prompt for login item
        if UserDefaults.standard.bool(forKey: firstLaunchKey) == false {
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
            // Show login item prompt after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.promptLoginItem()
            }
        }

        // Set up reminder callback before initializing views
        timerManager.onShowReminder = { [weak self] in
            self?.showReminderOverlay()
        }

        setupStatusItem()
        setupBindings()

        // Start monitoring for editing apps
        appMonitor.startMonitoring()
    }

    // MARK: - Login Item

    private func promptLoginItem() {
        if #available(macOS 13.0, *) {
            let alert = NSAlert()
            alert.messageText = "开机启动 Faraway？"
            alert.informativeText = "选择开机自动启动 Faraway，以便更好地提醒您休息。"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "开机启动")
            alert.addButton(withTitle: "暂不")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                do {
                    try SMAppService.mainApp.register()
                } catch {
                    print("Failed to enable login item: \(error)")
                }
            }
        }
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = createStatusBarIcon(isActive: false)
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 480)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: StatusBarView()
                .environmentObject(appMonitor)
                .environmentObject(timerManager)
                .environmentObject(sessionTracker)
        )
        self.popover = popover

        updateStatusIcon(isActive: false)
    }

    @objc func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    // MARK: - Bindings

    private func setupBindings() {
        // Watch for active editing app changes
        appMonitor.$isEditingAppActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                guard let self = self else { return }
                self.updateStatusIcon(isActive: isActive)
                if isActive {
                    self.timerManager.startTimer()
                } else {
                    self.timerManager.pauseTimer()
                    // If editing app was closed (not on first launch), maybe show daily summary
                    // Only show if app has been running for at least 1 minute
                    if let launchDate = self.appLaunchDate,
                       Date().timeIntervalSince(launchDate) > 60,
                       self.sessionTracker.todayBreakCount > 0 {
                        self.showDailySummaryIfNeeded()
                    }
                }
            }
            .store(in: &cancellables)

        // Watch for timer completion -> show reminder
        timerManager.$shouldShowReminder
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShow in
                if shouldShow {
                    self?.showReminderOverlay()
                    self?.timerManager.shouldShowReminder = false
                }
            }
            .store(in: &cancellables)

        // Watch for screen lock
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenLocked),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenUnlocked),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
    }

    @objc private func screenLocked() {
        timerManager.pauseTimer()
    }

    @objc private func screenUnlocked() {
        // Start timer in global mode or when editing app is active
        if appMonitor.monitoringMode == .global || appMonitor.isEditingAppActive {
            timerManager.startTimer()
        }
    }

    // MARK: - Status Icon

    private func createStatusBarIcon(isActive: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let center = NSPoint(x: rect.midX, y: rect.midY)
            let opacity: CGFloat = isActive ? 1.0 : 0.3

            // Colors from design system
            let petalColors: [NSColor] = [
                NSColor(red: 251/255, green: 191/255, blue: 36/255, alpha: opacity),  // Sunflower
                NSColor(red: 255/255, green: 107/255, blue: 107/255, alpha: opacity),  // Coral
                NSColor(red: 78/255, green: 205/255, blue: 196/255, alpha: opacity),   // Mint
                NSColor(red: 167/255, green: 139/255, blue: 250/255, alpha: opacity), // Lavender
                NSColor(red: 56/255, green: 189/255, blue: 248/255, alpha: opacity), // Sky
            ]

            // Draw 8 petals around the eye
            let petalRadius: CGFloat = 1.2
            let orbitRadius: CGFloat = 5.5
            let angleStep = (2 * CGFloat.pi) / 8

            for i in 0..<8 {
                let angle = CGFloat(i) * angleStep - CGFloat.pi / 2
                let x = center.x + orbitRadius * cos(angle)
                let y = center.y + orbitRadius * sin(angle)
                let colorIndex = i % petalColors.count

                let petalRect = NSRect(x: x - petalRadius, y: y - petalRadius, width: petalRadius * 2, height: petalRadius * 2)
                let petalPath = NSBezierPath(ovalIn: petalRect)
                petalColors[colorIndex].setFill()
                petalPath.fill()
            }

            // Draw eye ellipse
            let eyeRect = NSRect(x: center.x - 3, y: center.y - 2, width: 6, height: 4)
            let eyePath = NSBezierPath(ovalIn: eyeRect)
            NSColor(white: 1.0, alpha: opacity).setStroke()
            eyePath.lineWidth = 0.8
            eyePath.stroke()

            // Draw pupil
            let pupilRect = NSRect(x: center.x - 1, y: center.y - 1, width: 2, height: 2)
            let pupilPath = NSBezierPath(ovalIn: pupilRect)
            NSColor(white: 1.0, alpha: opacity).setFill()
            pupilPath.fill()

            return true
        }
        return image
    }

    private func updateStatusIcon(isActive: Bool) {
        guard let button = statusItem?.button else { return }

        // Use custom icon based on design system
        button.image = createStatusBarIcon(isActive: isActive)
        button.image?.isTemplate = false
    }

    // MARK: - Reminder Overlay

    func showReminderOverlay() {
        guard let screen = NSScreen.main else { return }

        let message = MessageProvider.shared.nextMessage()
        sessionTracker.recordBreak()

        let overlayView = ReminderOverlayView(
            message: message,
            onDismiss: { [weak self] in
                self?.dismissOverlay()
            }
        )
        .environmentObject(sessionTracker)

        let hostingView = NSHostingController(rootView: overlayView)

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingView
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.setFrame(screen.frame, display: true)

        self.overlayWindow = window

        // Fade in
        window.alphaValue = 0
        window.orderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.8
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 1
        }
    }

    func dismissOverlay() {
        guard let window = overlayWindow else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.5
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            self?.overlayWindow = nil
            // Restart timer for next cycle
            self?.timerManager.resetAndStart()
        })
    }

    // MARK: - Daily Summary

    private var lastSummaryDate: Date?
    private var appLaunchDate: Date?

    func showDailySummaryIfNeeded() {
        // Don't show summary immediately after app launch - wait at least 1 minute
        if let launchDate = appLaunchDate,
           Date().timeIntervalSince(launchDate) < 60 {
            return
        }

        let calendar = Calendar.current
        if let last = lastSummaryDate, calendar.isDateInToday(last) {
            return // Already shown today
        }

        // Only show if it's been at least 30 minutes of session
        guard sessionTracker.todayTotalGuardMinutes >= 30 else { return }

        // Small delay before showing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showDailySummary()
        }
    }

    func showDailySummary() {
        guard let screen = NSScreen.main else { return }
        lastSummaryDate = Date()

        let summaryView = DailySummaryView(
            breakCount: sessionTracker.todayBreakCount,
            totalRelaxSeconds: sessionTracker.todayTotalRelaxSeconds,
            guardHours: sessionTracker.todayTotalGuardMinutes / 60.0,
            onDismiss: { [weak self] in
                self?.dismissSummary()
            }
        )

        let hostingView = NSHostingController(rootView: summaryView)

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingView
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.setFrame(screen.frame, display: true)

        self.summaryWindow = window
        window.alphaValue = 0
        window.orderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.8
            window.animator().alphaValue = 1
        }
    }

    func dismissSummary() {
        guard let window = summaryWindow else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.5
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            self?.summaryWindow = nil
        })
    }
}
