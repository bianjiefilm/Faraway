import Foundation
import SwiftUI
import Combine

/// Dedicated long-term memory for tracking emotional milestones and streaks
class MilestoneManager: ObservableObject {
    static let shared = MilestoneManager()

    @AppStorage("Milestone_EffectiveRests") var totalEffectiveRests: Int = 0
    @AppStorage("Milestone_ConsecutiveDays") var consecutiveDays: Int = 0
    @AppStorage("Milestone_LastActiveDateString") var lastActiveDateString: String = ""

    /// Highest priority message block (if available, overrides any other messages in StatusBarView)
    @Published var currentMilestoneMessage: String?
    
    private var effectiveRestThresholds: [Int: String] {
        if EditionManager.shared.isSunflower {
            return [
                1: L10n.text("milestone.one.sunflower"),
                50: L10n.text("milestone.50"),
                200: L10n.text("milestone.200"),
                500: L10n.text("milestone.500"),
                1000: L10n.text("milestone.1000.sunflower"),
                2000: L10n.text("milestone.2000.sunflower"),
                5000: L10n.text("milestone.5000")
            ]
        } else {
            return [
                1: L10n.text("milestone.one.generic"),
                50: L10n.text("milestone.50"),
                200: L10n.text("milestone.200"),
                500: L10n.text("milestone.500"),
                1000: L10n.text("milestone.1000.generic"),
                2000: L10n.text("milestone.2000.generic"),
                5000: L10n.text("milestone.5000")
            ]
        }
    }

    private var consecutiveDayThresholds: [Int: String] {
        if EditionManager.shared.isSunflower {
            return [
                7: L10n.text("milestone.week"),
                30: L10n.text("milestone.month"),
                100: L10n.text("milestone.100.generic"),
                365: L10n.text("milestone.365")
            ]
        } else {
            return [
                7: L10n.text("milestone.week"),
                30: L10n.text("milestone.month"),
                100: L10n.text("milestone.100.sunflower"),
                365: L10n.text("milestone.365")
            ]
        }
    }

    private init() {
        checkAndCleanStreaks()
    }
    
    /// Triggered ONLY when the user manually clicks "I rested" after a full 20s countdown
    func recordEffectiveRest() {
        // 1. Increment raw count
        totalEffectiveRests += 1
        
        // 2. Check and Increment Consecutive Days
        updateConsecutiveDays()
        
        // 3. Evaluate any message trigger
        evaluateMilestones()
    }
    
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func checkAndCleanStreaks() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard !lastActiveDateString.isEmpty, let lastActive = formatter.date(from: lastActiveDateString) else { return }
        
        let components = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastActive), to: Calendar.current.startOfDay(for: Date()))
        
        // If more than 1 day has passed, streak is broken
        if let days = components.day, days > 1 {
            // Note: the streak is frozen until the next effective rest. 
            // Depending on design, we might reset it here, but generally a streak resets on failure to execute today/yesterday.
            if days >= 2 {
                consecutiveDays = 0
            }
        }
    }
    
    private func updateConsecutiveDays() {
        let today = todayString
        
        if lastActiveDateString.isEmpty {
            consecutiveDays = 1
            lastActiveDateString = today
            return
        }
        
        if lastActiveDateString == today {
            // Already counted today
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let lastActiveDate = formatter.date(from: lastActiveDateString), let currentDate = formatter.date(from: today) {
            let days = Calendar.current.dateComponents([.day], from: lastActiveDate, to: currentDate).day ?? 0
            
            if days == 1 {
                // Streak continues!
                consecutiveDays += 1
            } else if days > 1 {
                // Streak broken
                consecutiveDays = 1
            }
        } else {
            consecutiveDays = 1
        }
        
        lastActiveDateString = today
    }
    
    private func evaluateMilestones() {
        // Evaluate effective rests
        if let msg = effectiveRestThresholds[totalEffectiveRests] {
            currentMilestoneMessage = msg
            return
        }
        
        // Evaluate consecutive days (only trigger once when day increments to exact threshold)
        // Note: The message will persist until overwritten by weather/default when they restart the app next day,
        // or we can allow it to persist for the day. For simplicity, we just set `currentMilestoneMessage`.
        if lastActiveDateString == todayString, let msg = consecutiveDayThresholds[consecutiveDays] {
            // But we only want to show the consecutive day message if we just hit it.
            // Since this runs during `recordEffectiveRest`, if we just hit it today, we show it.
            // We should ensure it doesn't overwrite a rarer `effectiveRests` message though.
            // The `effectiveRests` took precedence in the `if` above.
            currentMilestoneMessage = msg
        }
    }
}
