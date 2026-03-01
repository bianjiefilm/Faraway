import Foundation
import Combine

/// Manages the 20-minute countdown timer
class TimerManager: ObservableObject {
    static let shared = TimerManager()

    /// Total interval in seconds (20 minutes)
    let intervalSeconds: Int = 20 * 60

    @Published var secondsRemaining: Int = 20 * 60
    @Published var isRunning = false
    @Published var shouldShowReminder = false

    /// Callback for showing reminder overlay (set by AppDelegate)
    var onShowReminder: (() -> Void)?

    private var timer: Timer?

    var formattedTimeRemaining: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        1.0 - (Double(secondsRemaining) / Double(intervalSeconds))
    }

    private init() {}

    func startTimer() {
        guard !isRunning else { return }
        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
            } else {
                self.timerCompleted()
            }
        }
        timer?.tolerance = 0.5
        RunLoop.current.add(timer!, forMode: .common)
    }

    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func resetAndStart() {
        secondsRemaining = intervalSeconds
        isRunning = false
        timer?.invalidate()
        timer = nil

        // Restart if editing app is active OR in global mode
        if AppMonitor.shared.isEditingAppActive || AppMonitor.shared.monitoringMode == .global {
            startTimer()
        }
    }

    /// Trigger reminder immediately
    func triggerReminderNow() {
        pauseTimer()
        shouldShowReminder = true
    }

    private func timerCompleted() {
        pauseTimer()
        shouldShowReminder = true
    }
}
