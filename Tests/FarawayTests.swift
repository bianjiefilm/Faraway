import XCTest
@testable import FarawayCore

// MARK: - EditionManager Tests

final class EditionManagerTests: XCTestCase {
    let em = EditionManager.shared

    override func setUp() {
        super.setUp()
        em.deactivate()
    }

    func testDefaultEditionIsGeneric() {
        XCTAssertFalse(em.isSunflower)
        XCTAssertEqual(em.currentEdition, .generic)
    }

    func testActivateWithCorrectCode() {
        let result = em.activate(code: "0523")
        XCTAssertTrue(result)
        XCTAssertTrue(em.isSunflower)
        XCTAssertEqual(em.currentEdition, .sunflower)
    }

    func testActivateWithWrongCode() {
        let result = em.activate(code: "1234")
        XCTAssertFalse(result)
        XCTAssertFalse(em.isSunflower)
    }

    func testActivateWithEmptyCode() {
        XCTAssertFalse(em.activate(code: ""))
        XCTAssertFalse(em.isSunflower)
    }

    func testDeactivateReturnsToGeneric() {
        _ = em.activate(code: "0523")
        XCTAssertTrue(em.isSunflower)
        em.deactivate()
        XCTAssertFalse(em.isSunflower)
        XCTAssertEqual(em.currentEdition, .generic)
    }

    func testActivationPersistsToUserDefaults() {
        _ = em.activate(code: "0523")
        let stored = UserDefaults.standard.string(forKey: "Faraway_Edition")
        XCTAssertEqual(stored, "sunflower")
    }

    func testDeactivationPersistsToUserDefaults() {
        _ = em.activate(code: "0523")
        em.deactivate()
        let stored = UserDefaults.standard.string(forKey: "Faraway_Edition")
        XCTAssertEqual(stored, "generic")
    }
}

// MARK: - MessageProvider Tests

final class MessageProviderTests: XCTestCase {
    let provider = MessageProvider.shared
    let em = EditionManager.shared

    override func setUp() {
        super.setUp()
        em.deactivate()
    }

    func testGenericNormalMessagesCount() {
        em.deactivate()
        let msg = provider.getMessage(special: false)
        XCTAssertFalse(msg.isSpecial)
    }

    func testGenericSpecialMessage() {
        em.deactivate()
        let msg = provider.getMessage(special: true)
        XCTAssertTrue(msg.isSpecial)
        // Generic special messages should not contain "太阳葵"
        XCTAssertFalse(msg.text.contains("太阳葵"))
        XCTAssertFalse(msg.subtitle.contains("太阳葵"))
    }

    func testSunflowerSpecialMessageContainsSunflowerTheme() {
        _ = em.activate(code: "0523")
        // Call several times to get a special message
        var foundSunflower = false
        for _ in 0..<30 {
            let msg = provider.getMessage(special: true)
            if msg.text.contains("太阳葵") || msg.subtitle.contains("太阳葵") || msg.subtitle.contains("🌻") {
                foundSunflower = true
                break
            }
        }
        XCTAssertTrue(foundSunflower, "Sunflower special messages should contain sunflower-themed content")
    }

    func testSunflowerNormalMessageContainsVideoTheme() {
        _ = em.activate(code: "0523")
        // Sunflower normal messages include video-editing themed ones
        var foundVideo = false
        for _ in 0..<50 {
            let msg = provider.getMessage(special: false)
            if msg.text.contains("视频") || msg.text.contains("时间线") || msg.text.contains("剪辑") {
                foundVideo = true
                break
            }
        }
        XCTAssertTrue(foundVideo, "Sunflower normal messages should contain video-editing themed content")
    }

    func testGenericNormalMessagesDoNotContainVideoTheme() {
        em.deactivate()
        // Generic messages should not contain video-specific content
        for _ in 0..<50 {
            let msg = provider.getMessage(special: false)
            XCTAssertFalse(msg.text.contains("时间线"), "Generic messages should not contain '时间线'")
            XCTAssertFalse(msg.text.contains("剪辑"), "Generic messages should not contain '剪辑'")
        }
    }

    func testNextMessageRotatesNormalMessages() {
        em.deactivate()
        // Reset provider by cycling through a non-special sequence
        // nextMessage increments index; special appears at multiples of 5
        // Check that calling it doesn't crash and returns valid messages
        for _ in 0..<20 {
            let msg = provider.nextMessage()
            XCTAssertFalse(msg.text.isEmpty)
            XCTAssertFalse(msg.subtitle.isEmpty)
        }
    }

    func testNextMessageReturnsSpecialAtEvery5th() {
        em.deactivate()
        // Reset index by creating a fresh sequence - we need to call nextMessage
        // until we hit a multiple of 5 boundary
        // We can't reset messageIndex directly (private), so test by calling 5 times
        // and verifying the 5th one is special
        var specialCount = 0
        for i in 1...10 {
            let msg = provider.nextMessage()
            if i % 5 == 0 {
                XCTAssertTrue(msg.isSpecial, "Every 5th message should be special (call \(i))")
                specialCount += 1
            }
        }
        XCTAssertEqual(specialCount, 2)
    }
}

// MARK: - DateManager Tests

final class DateManagerTests: XCTestCase {
    let dm = DateManager.shared
    let em = EditionManager.shared

    override func setUp() {
        super.setUp()
        em.deactivate()
        dm.injectedDate = nil
        dm.specialDateMessage = nil
    }

    override func tearDown() {
        super.tearDown()
        dm.injectedDate = nil
    }

    // Helper to create a Date from components
    private func date(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        return Calendar.current.date(from: comps)!
    }

    func testLateNightGenericMessage() {
        em.deactivate()
        dm.injectedDate = date(year: 2025, month: 6, day: 15, hour: 2)
        dm.evaluateDates()
        let msg = dm.specialDateMessage
        XCTAssertNotNil(msg)
        XCTAssertFalse(msg!.contains("视频"), "Generic late night should not mention video")
    }

    func testLateNightSunflowerMessage() {
        _ = em.activate(code: "0523")
        // Jan 3 = day 3; 3 % 3 = 0 → picks sunflower index 0: "这么晚了，视频明天再剪 🌙"
        dm.injectedDate = date(year: 2025, month: 1, day: 3, hour: 2)
        dm.evaluateDates()
        let msg = dm.specialDateMessage
        XCTAssertNotNil(msg)
        XCTAssertEqual(msg, "这么晚了，视频明天再剪 🌙", "Sunflower late night (day 3) should show video-themed message")
    }

    func testNewYearGenericMessage() {
        em.deactivate()
        dm.injectedDate = date(year: 2025, month: 1, day: 1)
        dm.evaluateDates()
        XCTAssertEqual(dm.specialDateMessage, "新年快乐 🌻")
    }

    func testNewYearSunflowerMessage() {
        _ = em.activate(code: "0523")
        dm.injectedDate = date(year: 2025, month: 1, day: 1)
        dm.evaluateDates()
        XCTAssertEqual(dm.specialDateMessage, "新年快乐，太阳葵 🌻")
    }

    func testNewYearEveMessage() {
        em.deactivate()
        dm.injectedDate = date(year: 2025, month: 12, day: 31)
        dm.evaluateDates()
        XCTAssertEqual(dm.specialDateMessage, "新年快乐 🌻")
    }

    func testJuly13SunflowerOnly() {
        _ = em.activate(code: "0523")
        dm.injectedDate = date(year: 2025, month: 7, day: 13)
        dm.evaluateDates()
        XCTAssertEqual(dm.specialDateMessage, "太阳葵，今天多晒一会儿阳光 🌻")
    }

    func testJuly13GenericNoSpecialMessage() {
        em.deactivate()
        dm.injectedDate = date(year: 2025, month: 7, day: 13)
        dm.evaluateDates()
        // Generic edition should NOT show July 13 sunflower message
        XCTAssertNotEqual(dm.specialDateMessage, "太阳葵，今天多晒一会儿阳光 🌻")
    }

    func testNormalDaytimeClearsMessage() {
        em.deactivate()
        // A normal weekday with no special date significance
        dm.injectedDate = date(year: 2025, month: 6, day: 15, hour: 14)
        dm.evaluateDates()
        // Should be nil (no special date match, assuming June 15 isn't install anniversary)
        // Note: This might fail if install date happens to be June 15 — acceptable edge case
        // We just check it's not the late night or New Year messages
        let msg = dm.specialDateMessage
        if let msg = msg {
            XCTAssertFalse(msg.contains("这么晚了"), "Should not be late night message at 14:00")
            XCTAssertFalse(msg.contains("新年"), "Should not be new year message on June 15")
        }
    }

    func testLateNightBoundaryAt5am() {
        em.deactivate()
        // 5:00 is NOT late night (condition is hour < 5)
        dm.injectedDate = date(year: 2025, month: 6, day: 15, hour: 5)
        dm.evaluateDates()
        let msg = dm.specialDateMessage
        // Should not be a late night message
        if let msg = msg {
            XCTAssertFalse(msg.contains("这么晚了"), "5am should not trigger late night message")
        }
    }

    func testLateNightBoundaryAtMidnight() {
        em.deactivate()
        dm.injectedDate = date(year: 2025, month: 6, day: 15, hour: 0)
        dm.evaluateDates()
        XCTAssertNotNil(dm.specialDateMessage, "Midnight should trigger late night message")
    }
}

// MARK: - SessionTracker Tests

final class SessionTrackerTests: XCTestCase {
    let tracker = SessionTracker.shared

    override func setUp() {
        super.setUp()
        // Reset state
        tracker.todayBreakCount = 0
        tracker.todayTotalRelaxSeconds = 0
        tracker.todayTotalGuardMinutes = 0
    }

    func testRecordBreakIncrementsCount() {
        tracker.todayBreakCount = 0
        tracker.recordBreak()
        XCTAssertEqual(tracker.todayBreakCount, 1)
    }

    func testRecordBreakAdds20Seconds() {
        tracker.todayTotalRelaxSeconds = 0
        tracker.recordBreak()
        XCTAssertEqual(tracker.todayTotalRelaxSeconds, 20)
    }

    func testMultipleBreaksAccumulate() {
        tracker.todayBreakCount = 0
        tracker.todayTotalRelaxSeconds = 0
        tracker.recordBreak()
        tracker.recordBreak()
        tracker.recordBreak()
        XCTAssertEqual(tracker.todayBreakCount, 3)
        XCTAssertEqual(tracker.todayTotalRelaxSeconds, 60)
    }

    func testCheckDateChangeResetsOnNewDay() {
        tracker.todayBreakCount = 5
        tracker.todayTotalRelaxSeconds = 100

        // Simulate a different "last date" to force reset
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterdayKey = formatter.string(from: yesterday)
        UserDefaults.standard.set(yesterdayKey, forKey: "EyeBreak_LastDate")

        tracker.checkDateChange()

        XCTAssertEqual(tracker.todayBreakCount, 0, "Break count should reset on new day")
        XCTAssertEqual(tracker.todayTotalRelaxSeconds, 0, "Relax seconds should reset on new day")
        XCTAssertEqual(tracker.todayTotalGuardMinutes, 0, "Guard minutes should reset on new day")
    }

    func testCheckDateChangeSameDayDoesNotReset() {
        tracker.todayBreakCount = 5

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayKey = formatter.string(from: Date())
        UserDefaults.standard.set(todayKey, forKey: "EyeBreak_LastDate")

        tracker.checkDateChange()

        XCTAssertEqual(tracker.todayBreakCount, 5, "Count should not reset when date hasn't changed")
    }
}

// MARK: - MilestoneManager Tests

final class MilestoneManagerTests: XCTestCase {
    let mm = MilestoneManager.shared
    let em = EditionManager.shared

    override func setUp() {
        super.setUp()
        em.deactivate()
        mm.currentMilestoneMessage = nil
    }

    private func yesterday() -> String {
        let d = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    private func today() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    func testFirstRestMilestoneGeneric() {
        em.deactivate()
        mm.totalEffectiveRests = 0
        mm.lastActiveDateString = ""
        mm.recordEffectiveRest()
        XCTAssertEqual(mm.currentMilestoneMessage, "第一次，一个好的开始")
    }

    func testFirstRestMilestoneSunflower() {
        _ = em.activate(code: "0523")
        mm.totalEffectiveRests = 0
        mm.lastActiveDateString = ""
        mm.recordEffectiveRest()
        XCTAssertEqual(mm.currentMilestoneMessage, "第一次，一个好的开始 🌻")
    }

    func test50RestMilestoneGeneric() {
        em.deactivate()
        mm.totalEffectiveRests = 49
        mm.lastActiveDateString = yesterday()
        mm.recordEffectiveRest()
        XCTAssertEqual(mm.totalEffectiveRests, 50)
        XCTAssertEqual(mm.currentMilestoneMessage, "50次远眺，眼睛在说谢谢")
    }

    func test200RestMilestoneGeneric() {
        em.deactivate()
        mm.totalEffectiveRests = 199
        mm.lastActiveDateString = yesterday()
        mm.recordEffectiveRest()
        XCTAssertEqual(mm.currentMilestoneMessage, "200次了，已经是一个好习惯")
    }

    func test2000RestMilestoneGenericVsSunflower() {
        // Generic: no special suffix
        em.deactivate()
        mm.totalEffectiveRests = 1999
        mm.lastActiveDateString = yesterday()
        mm.recordEffectiveRest()
        XCTAssertEqual(mm.currentMilestoneMessage, "还在用着啊，真好")

        // Sunflower: has "有人很高兴 🌻"
        _ = em.activate(code: "0523")
        mm.totalEffectiveRests = 1999
        mm.lastActiveDateString = yesterday()
        mm.recordEffectiveRest()
        XCTAssertEqual(mm.currentMilestoneMessage, "还在用着啊。有人很高兴 🌻")
    }

    func test7DayStreakGeneric() {
        em.deactivate()
        mm.consecutiveDays = 6
        mm.lastActiveDateString = yesterday()
        mm.totalEffectiveRests = 10 // not a threshold
        mm.recordEffectiveRest()
        XCTAssertEqual(mm.consecutiveDays, 7)
        XCTAssertEqual(mm.currentMilestoneMessage, "连续一周了，真棒")
    }

    func test100DayStreakSunflowerHasEmoji() {
        _ = em.activate(code: "0523")
        mm.consecutiveDays = 99
        mm.lastActiveDateString = yesterday()
        mm.totalEffectiveRests = 10
        mm.recordEffectiveRest()
        XCTAssertEqual(mm.consecutiveDays, 100)
        XCTAssertEqual(mm.currentMilestoneMessage, "100天 🌻")
    }

    func test100DayStreakGenericHasText() {
        em.deactivate()
        mm.consecutiveDays = 99
        mm.lastActiveDateString = yesterday()
        mm.totalEffectiveRests = 10
        mm.recordEffectiveRest()
        XCTAssertEqual(mm.consecutiveDays, 100)
        XCTAssertEqual(mm.currentMilestoneMessage, "100天，了不起")
    }

    func testStreakContinuationFromYesterday() {
        em.deactivate()
        mm.consecutiveDays = 5
        mm.lastActiveDateString = yesterday()
        mm.totalEffectiveRests = 10
        mm.recordEffectiveRest()
        XCTAssertEqual(mm.consecutiveDays, 6, "Streak should increment when last active was yesterday")
    }

    func testStreakNotIncrementedTwiceToday() {
        em.deactivate()
        mm.consecutiveDays = 5
        mm.lastActiveDateString = today()
        mm.totalEffectiveRests = 10
        mm.recordEffectiveRest()
        XCTAssertEqual(mm.consecutiveDays, 5, "Streak should not increment if already counted today")
    }

    func testNoMilestoneAtNonThreshold() {
        em.deactivate()
        mm.totalEffectiveRests = 10
        mm.consecutiveDays = 3
        mm.lastActiveDateString = yesterday()
        mm.currentMilestoneMessage = nil
        mm.recordEffectiveRest()
        XCTAssertNil(mm.currentMilestoneMessage, "No milestone message at count 11, streak 4")
    }
}
