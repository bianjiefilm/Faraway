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
        
        // 1. Check Late Night (00:00 - 05:00)
        let hour = Calendar.current.component(.hour, from: now)
        if hour >= 0 && hour < 5 {
            // Late night working
            let lateMessages = [
                "这么晚了，视频明天再剪 🌙",
                "夜很深了，眼睛比deadline重要",
                "别熬了，要早点睡才能晒到明天的太阳 🌻"
            ]
            // We just randomly pick one for the session, or cycle them. 
            // We can pick based on day of year to preserve stability per night
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: now) ?? 0
            specialDateMessage = lateMessages[dayOfYear % lateMessages.count]
            return
        }
        
        // 2. Exact Calendar Dates
        let md = formatter.string(from: now)
        
        if md == "03-01" {
            specialDateMessage = "这个App今天一岁了"
            return
        }
        
        if md == "07-13" {
            specialDateMessage = "太阳葵，今天多晒一会儿阳光 🌻"
            return
        }
        
        // TODO: Lunar string for 5月23日 if needed, skipping complex lunar mapping for now and using Solar as primary.
        
        // 3. New Year & Eve (Simple approximation: Jan 1)
        if md == "01-01" || md == "12-31" {
            specialDateMessage = "新年快乐，太阳葵 🌻"
            return
        }

        // 4. Install Anniversary Check (March 2 or dynamic InstallDate)
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
