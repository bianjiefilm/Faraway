import Foundation
import Combine
import SwiftUI

class DateManager: ObservableObject {
    static let shared = DateManager()

    /// If this has a value, it overrides weather messages
    @Published var specialDateMessage: String?

    /// For testing purposes only
    var injectedDate: Date?

    // Date formatter for comparisons
    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MM-dd"
        return df
    }()

    // Chinese lunar calendar for lunar date checks
    private let chineseCalendar = Calendar(identifier: .chinese)

    // We get the install date from User Defaults (set on first launch)
    @AppStorage("InstallDateString") private var installDateString: String = ""

    private init() {
        if installDateString.isEmpty {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            installDateString = df.string(from: Date())
        }
    }

    /// Run this periodically or on app wake to check date/time messages
    func evaluateDates() {
        let now = injectedDate ?? Date()
        let isSunflower = EditionManager.shared.isSunflower

        // 1. Check Late Night (00:00 - 05:00)
        let hour = Calendar.current.component(.hour, from: now)
        if hour >= 0 && hour < 5 {
            let lateMessages: [String]
            if isSunflower {
                lateMessages = [
                    "这么晚了，视频明天再剪 🌙",
                    "夜很深了，眼睛比deadline重要",
                    "别熬了，要早点睡才能晒到明天的太阳 🌻"
                ]
            } else {
                lateMessages = [
                    "这么晚了，明天再忙 🌙",
                    "夜很深了，眼睛比deadline重要",
                    "别熬了，要早点睡才能晒到明天的太阳"
                ]
            }
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: now) ?? 0
            specialDateMessage = lateMessages[dayOfYear % lateMessages.count]
            return
        }

        // 2. Exact Calendar Dates
        let md = formatter.string(from: now)

        // Sunflower-only dates
        if isSunflower {
            if md == "07-13" {
                specialDateMessage = "太阳葵，今天多晒一会儿阳光 🌻"
                return
            }

            // Lunar calendar date check: 五月廿三 (5th month, 23rd day)
            let lunarComponents = chineseCalendar.dateComponents([.month, .day], from: now)
            if lunarComponents.month == 5 && lunarComponents.day == 23 {
                specialDateMessage = "生日快乐，太阳葵 🎂🌻"
                return
            }
        }

        // 3. New Year & Eve
        if md == "01-01" || md == "12-31" {
            if isSunflower {
                specialDateMessage = "新年快乐，太阳葵 🌻"
            } else {
                specialDateMessage = "新年快乐 🌻"
            }
            return
        }

        // 4. Install Anniversary Check
        let fullFormatter = DateFormatter()
        fullFormatter.dateFormat = "yyyy-MM-dd"

        if let installDate = fullFormatter.date(from: installDateString) {
            let years = Calendar.current.dateComponents([.year], from: installDate, to: now).year ?? 0
            if years > 0 && md == formatter.string(from: installDate) {
                if years == 1 {
                    specialDateMessage = "陪你一年了"
                } else if years == 2 {
                    specialDateMessage = "还在呢"
                } else {
                    specialDateMessage = "陪你\(years)年了"
                }
                return
            }
        }

        // If nothing matches, clear it so weather or milestone can take over
        specialDateMessage = nil
    }
}
