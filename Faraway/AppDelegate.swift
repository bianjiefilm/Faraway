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
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
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
        // Right-click shows emergency menu
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showEmergencyMenu()
            return
        }
        guard let popover = popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showEmergencyMenu() {
        let menu = NSMenu()
        let closeItem = NSMenuItem(title: "紧急关闭提醒", action: #selector(emergencyDismissOverlay), keyEquivalent: "")
        closeItem.target = self
        menu.addItem(closeItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "退出 Faraway", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        // Reset menu so left-click still opens popover
        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.menu = nil
        }
    }

    @objc private func emergencyDismissOverlay() {
        forceCloseOverlay()
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
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size)
        img.lockFocus()

        if isActive {
            drawActiveIcon(secondsRemaining: secondsRemaining)
        } else {
            drawInactiveIcon()
        }

        img.unlockFocus()
        return img
    }

    private func drawActiveIcon(secondsRemaining: Int) {
        let s = NSColor(red: 251/255, green: 191/255, blue: 36/255, alpha: 1)
        // Eye Center
        NSColor.white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 5.5, y: 6.5, width: 7, height: 5)).fill()
        NSColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1).setStroke()
        let eye = NSBezierPath(ovalIn: NSRect(x: 5.5, y: 6.5, width: 7, height: 5))
        eye.lineWidth = 1.0
        eye.stroke()

        // Pupil
        s.setFill()
        NSBezierPath(ovalIn: NSRect(x: 7.8, y: 7.8, width: 2.4, height: 2.4)).fill()

        if secondsRemaining <= 60 && secondsRemaining > 0 {
            // Draw progress circle pre-warning
            let progress = CGFloat(secondsRemaining) / 60.0
            
            let trackPath = NSBezierPath(ovalIn: NSRect(x: 1.5, y: 1.5, width: 15, height: 15))
            NSColor.white.withAlphaComponent(0.2).setStroke()
            trackPath.lineWidth = 1.5
            trackPath.stroke()
            
            let center = NSPoint(x: 9, y: 9)
            let radius: CGFloat = 7.5
            let path = NSBezierPath()
            let endAngle = 90.0 - (360.0 * progress)
            path.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: endAngle, clockwise: true)
            
            s.setStroke()
            path.lineWidth = 1.5
            path.lineCapStyle = .round
            path.stroke()
        } else {
            // Draw regular petals
            let c = NSColor(red: 255/255, green: 107/255, blue: 107/255, alpha: 1)
            let m = NSColor(red: 78/255, green: 205/255, blue: 196/255, alpha: 1)
            let k = NSColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1)

            drawDot(x: 9, y: 16, color: s)
            drawDot(x: 14, y: 14, color: c)
            drawDot(x: 16, y: 9, color: m)
            drawDot(x: 14, y: 4, color: k)
            drawDot(x: 9, y: 2, color: s)
            drawDot(x: 4, y: 4, color: c)
            drawDot(x: 2, y: 9, color: m)
            drawDot(x: 4, y: 14, color: k)
        }
    }

    private func drawInactiveIcon() {
        let gray = NSColor(white: 1.0, alpha: 0.4)

        // Petals
        drawDot(x: 9, y: 16, color: gray)
        drawDot(x: 14, y: 14, color: gray)
        drawDot(x: 16, y: 9, color: gray)
        drawDot(x: 14, y: 4, color: gray)
        drawDot(x: 9, y: 2, color: gray)
        drawDot(x: 4, y: 4, color: gray)
        drawDot(x: 2, y: 9, color: gray)
        drawDot(x: 4, y: 14, color: gray)

        // Eye
        gray.setStroke()
        let eye = NSBezierPath(ovalIn: NSRect(x: 6, y: 7, width: 6, height: 4))
        eye.lineWidth = 0.8
        eye.stroke()

        // Pupil
        gray.setFill()
        NSBezierPath(ovalIn: NSRect(x: 8, y: 8, width: 2, height: 2)).fill()
    }

    private func drawDot(x: CGFloat, y: CGFloat, color: NSColor) {
        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)).fill()
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

        // Add Esc key monitor for emergency exit
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
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
