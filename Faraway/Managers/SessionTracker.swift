import Foundation
import Combine

/// Tracks daily session statistics
class SessionTracker: ObservableObject {
    static let shared = SessionTracker()

    @Published var todayBreakCount: Int = 0
    @Published var todayTotalRelaxSeconds: Int = 0
    @Published var todayTotalGuardMinutes: Double = 0

    private var guardStartTime: Date?
    private var currentDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private init() {
        loadTodayStats()
        startGuardTimer()
    }

    // MARK: - Recording

    func recordBreak() {
        todayBreakCount += 1
        todayTotalRelaxSeconds += 20 // Each break is 20 seconds
        saveTodayStats()
    }

    // MARK: - Guard Time Tracking

    private var guardTimer: Timer?

    private func startGuardTimer() {
        // Update guard minutes every 60 seconds when monitoring is active
        guardTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if AppMonitor.shared.isEditingAppActive {
                self.todayTotalGuardMinutes += 1
                self.saveTodayStats()
            }
        }
        guardTimer?.tolerance = 5
    }

    // MARK: - Persistence

    private func saveTodayStats() {
        let key = currentDateKey
        let stats: [String: Any] = [
            "breakCount": todayBreakCount,
            "relaxSeconds": todayTotalRelaxSeconds,
            "guardMinutes": todayTotalGuardMinutes
        ]
        UserDefaults.standard.set(stats, forKey: "EyeBreak_Stats_\(key)")
    }

    private func loadTodayStats() {
        let key = currentDateKey
        if let stats = UserDefaults.standard.dictionary(forKey: "EyeBreak_Stats_\(key)") {
            todayBreakCount = stats["breakCount"] as? Int ?? 0
            todayTotalRelaxSeconds = stats["relaxSeconds"] as? Int ?? 0
            todayTotalGuardMinutes = stats["guardMinutes"] as? Double ?? 0
        } else {
            // New day, reset stats
            todayBreakCount = 0
            todayTotalRelaxSeconds = 0
            todayTotalGuardMinutes = 0
        }
    }

    /// Call this at midnight or when checking date changes
    func checkDateChange() {
        let key = currentDateKey
        let lastKey = UserDefaults.standard.string(forKey: "EyeBreak_LastDate") ?? ""
        if key != lastKey {
            // New day
            todayBreakCount = 0
            todayTotalRelaxSeconds = 0
            todayTotalGuardMinutes = 0
            UserDefaults.standard.set(key, forKey: "EyeBreak_LastDate")
        }
    }
}
