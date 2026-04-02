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
    private var isDismissing = false
    private var escKeyMonitor: Any?

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
            button.image = createStatusBarIcon(isActive: false, secondsRemaining: timerManager.secondsRemaining)
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

        updateStatusIcon(isActive: false, secondsRemaining: timerManager.secondsRemaining)
    }

    @objc func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
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
                self.updateStatusIcon(isActive: isActive, secondsRemaining: self.timerManager.secondsRemaining)
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

        // Watch for timer countdown to update icon progress ring
        timerManager.$secondsRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] seconds in
                guard let self = self else { return }
                let isActive = self.appMonitor.isEditingAppActive || self.appMonitor.monitoringMode == .global
                if isActive && seconds <= 60 {
                    self.updateStatusIcon(isActive: true, secondsRemaining: seconds)
                } else if isActive && seconds == self.timerManager.intervalSeconds {
                    // Reset to full petals when timer resets
                    self.updateStatusIcon(isActive: true, secondsRemaining: seconds)
                }
            }
            .store(in: &cancellables)

        // Watch for timer completion -> show reminder (single path only)
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

        // Watch for system sleep/wake to handle stuck overlays
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Check for date change every minute so stats reset properly at midnight
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.sessionTracker.checkDateChange()
        }.tolerance = 10
    }

    @objc private func screenLocked() {
        timerManager.pauseTimer()
    }

    @objc private func screenUnlocked() {
        // If overlay is stuck, dismiss it on unlock
        if overlayWindow != nil {
            forceCloseOverlay()
        }
        // Start timer in global mode or when editing app is active
        if appMonitor.monitoringMode == .global || appMonitor.isEditingAppActive {
            timerManager.startTimer()
        }
    }

    @objc private func systemWillSleep() {
        timerManager.pauseTimer()
        // If overlay is showing when going to sleep, dismiss it
        if overlayWindow != nil {
            forceCloseOverlay()
        }
    }

    @objc private func systemDidWake() {
        // If somehow overlay survived sleep, force close it
        if overlayWindow != nil {
            forceCloseOverlay()
        }
        // Restart timer after waking
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            if self.appMonitor.monitoringMode == .global || self.appMonitor.isEditingAppActive {
                self.timerManager.resetAndStart()
            }
        }
    }

    // MARK: - Status Icon

    private func createStatusBarIcon(isActive: Bool, secondsRemaining: Int) -> NSImage {
        let size = NSSize(width: 20, height: 20)

        // Use countdown ring mode when close to break
        if isActive && secondsRemaining <= 60 && secondsRemaining > 0 {
            return createCountdownIcon(secondsRemaining: secondsRemaining, size: size)
        }

        // Use asset catalog images
        let imageName = isActive ? "StatusBarActive" : "StatusBarInactive"
        if let img = NSImage(named: imageName) {
            img.size = size
            return img
        }
        // Fallback: simple circle if asset not found
        let fallback = NSImage(size: size, flipped: false) { rect in
            (isActive ? NSColor.orange : NSColor.gray).setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 3, dy: 3)).fill()
            return true
        }
        return fallback
    }

    private func createCountdownIcon(secondsRemaining: Int, size: NSSize) -> NSImage {
        let img = NSImage(size: size, flipped: false) { rect in
            let cx = size.width / 2, cy = size.height / 2
            let radius = min(size.width, size.height) / 2 - 1.5
            let sunflower = NSColor(red: 251/255, green: 183/255, blue: 36/255, alpha: 1)
            let progress = CGFloat(secondsRemaining) / 60.0

            // Track ring
            let inset: CGFloat = 1.5
            let trackPath = NSBezierPath(ovalIn: NSRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2))
            NSColor.white.withAlphaComponent(0.15).setStroke()
            trackPath.lineWidth = 1.5
            trackPath.stroke()

            // Progress arc
            let arc = NSBezierPath()
            let endAngle = 90.0 - (360.0 * progress)
            arc.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: radius, startAngle: 90, endAngle: endAngle, clockwise: true)
            sunflower.setStroke()
            arc.lineWidth = 1.5
            arc.lineCapStyle = .round
            arc.stroke()

            // Small center dot
            sunflower.setFill()
            NSBezierPath(ovalIn: NSRect(x: cx - 2.5, y: cy - 2.5, width: 5, height: 5)).fill()

            return true
        }
        return img
    }

    private func updateStatusIcon(isActive: Bool, secondsRemaining: Int) {
        guard let button = statusItem?.button else { return }
        button.image = createStatusBarIcon(isActive: isActive, secondsRemaining: secondsRemaining)
        button.image?.isTemplate = false
    }

    // MARK: - Reminder Overlay

    func showReminderOverlay() {
        // Guard against double-trigger
        guard overlayWindow == nil, let screen = NSScreen.main else { return }

        isDismissing = false

        let message = MessageProvider.shared.nextMessage()

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

        // Add Esc key monitor for emergency exit (stored so it can be removed on dismiss)
        escKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Esc key
                self?.forceCloseOverlay()
                return nil
            }
            return event
        }

        self.overlayWindow = window

        // Fade in
        window.alphaValue = 0
        window.orderFront(nil)
        window.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.8
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 1
        }
    }

    func dismissOverlay() {
        guard let window = overlayWindow, !isDismissing else { return }
        isDismissing = true

        // Start fade-out animation
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.5
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.cleanupOverlay()
        })

        // Timeout fallback: if animation callback doesn't fire (e.g. after sleep),
        // force cleanup after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.cleanupOverlay()
        }
    }

    /// Force-close overlay without animation (emergency escape)
    func forceCloseOverlay() {
        guard overlayWindow != nil else { return }
        isDismissing = true
        cleanupOverlay()
    }

    /// Shared cleanup: close window and restart timer. Safe to call multiple times.
    private func cleanupOverlay() {
        guard let window = overlayWindow else { return }
        window.orderOut(nil)
        overlayWindow = nil
        isDismissing = false
        // Remove Esc key monitor to avoid accumulation across multiple overlays
        if let monitor = escKeyMonitor {
            NSEvent.removeMonitor(monitor)
            escKeyMonitor = nil
        }
        // Restart timer for next cycle
        timerManager.resetAndStart()
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
