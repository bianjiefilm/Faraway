import SwiftUI

/// A single reminder message with theme
struct ReminderMessage: Identifiable {
    let id = UUID()
    let text: String
    let subtitle: String
    let gradientColors: [Color]
    let isSpecial: Bool // 🌻 easter egg messages

    var gradient: LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Provides rotating reminder messages
class MessageProvider: ObservableObject {
    static let shared = MessageProvider()

    private var messageIndex = 0

    // MARK: - Generic Normal Messages

    private let genericNormalMessages: [ReminderMessage] = [
        ReminderMessage(
            text: "看看窗外吧\n远处的风景在等你 🌿",
            subtitle: "让眼睛去旅行 20 秒",
            gradientColors: [
                Color(red: 1, green: 107/255, blue: 107/255),
                Color(red: 1, green: 142/255, blue: 83/255),
                Color(red: 1, green: 230/255, blue: 109/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: "眼睛辛苦了\n让它呼吸 20 秒 ☁️",
            subtitle: "深呼吸，看远方",
            gradientColors: [
                Color(red: 78/255, green: 205/255, blue: 196/255),
                Color(red: 68/255, green: 176/255, blue: 158/255),
                Color(red: 56/255, green: 189/255, blue: 248/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: "世界不止屏幕这么大\n抬头看看 💜",
            subtitle: "窗外有好风景",
            gradientColors: [
                Color(red: 167/255, green: 139/255, blue: 250/255),
                Color(red: 129/255, green: 140/255, blue: 248/255),
                Color(red: 99/255, green: 102/255, blue: 241/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: "工作可以晚一点\n眼睛只有一双 ✨",
            subtitle: "照顾好自己",
            gradientColors: [
                Color(red: 1, green: 60/255, blue: 172/255),
                Color(red: 1, green: 107/255, blue: 107/255),
                Color(red: 251/255, green: 191/255, blue: 36/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: "事情不会跑掉的\n先让眼睛散散步 🍃",
            subtitle: "好的状态需要好的眼睛",
            gradientColors: [
                Color(red: 132/255, green: 204/255, blue: 22/255),
                Color(red: 78/255, green: 205/255, blue: 196/255),
                Color(red: 56/255, green: 189/255, blue: 248/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: "灵感需要休息\n眼睛也是 🌙",
            subtitle: "放空一下，说不定有新想法",
            gradientColors: [
                Color(red: 99/255, green: 102/255, blue: 241/255),
                Color(red: 167/255, green: 139/255, blue: 250/255),
                Color(red: 244/255, green: 114/255, blue: 182/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: "工作的节奏很重要\n休息的节奏也是 🎵",
            subtitle: "张弛有度",
            gradientColors: [
                Color(red: 245/255, green: 158/255, blue: 11/255),
                Color(red: 1, green: 107/255, blue: 107/255),
                Color(red: 244/255, green: 114/255, blue: 182/255)
            ],
            isSpecial: false
        ),
    ]

    // MARK: - Generic Special Messages

    private let genericSpecialMessages: [ReminderMessage] = [
        ReminderMessage(
            text: "你也需要\n看看远处的阳光",
            subtitle: "— 来自 Faraway",
            gradientColors: [
                Color(red: 251/255, green: 191/255, blue: 36/255),
                Color(red: 245/255, green: 158/255, blue: 11/255),
                Color(red: 1, green: 107/255, blue: 107/255)
            ],
            isSpecial: true
        ),
        ReminderMessage(
            text: "阳光在等你\n先休息一下",
            subtitle: "— ☀️",
            gradientColors: [
                Color(red: 37/255, green: 99/255, blue: 235/255),
                Color(red: 78/255, green: 205/255, blue: 196/255),
                Color(red: 167/255, green: 139/255, blue: 250/255)
            ],
            isSpecial: true
        ),
        ReminderMessage(
            text: "追光的路上\n别忘了你的眼睛",
            subtitle: "— ✨",
            gradientColors: [
                Color(red: 251/255, green: 191/255, blue: 36/255),
                Color(red: 132/255, green: 204/255, blue: 22/255),
                Color(red: 78/255, green: 205/255, blue: 196/255)
            ],
            isSpecial: true
        ),
    ]

    // MARK: - Sunflower Normal Messages (original)

    private let sunflowerNormalMessages: [ReminderMessage] = [
        ReminderMessage(
            text: "看看窗外吧\n远处的风景在等你 🌿",
            subtitle: "让眼睛去旅行 20 秒",
            gradientColors: [
                Color(red: 1, green: 107/255, blue: 107/255),
                Color(red: 1, green: 142/255, blue: 83/255),
                Color(red: 1, green: 230/255, blue: 109/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: "眼睛辛苦了\n让它呼吸 20 秒 ☁️",
            subtitle: "深呼吸，看远方",
            gradientColors: [
                Color(red: 78/255, green: 205/255, blue: 196/255),
                Color(red: 68/255, green: 176/255, blue: 158/255),
                Color(red: 56/255, green: 189/255, blue: 248/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: "世界不止屏幕这么大\n抬头看看 💜",
            subtitle: "窗外有好风景",
            gradientColors: [
                Color(red: 167/255, green: 139/255, blue: 250/255),
                Color(red: 129/255, green: 140/255, blue: 248/255),
                Color(red: 99/255, green: 102/255, blue: 241/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: "视频可以晚一点\n眼睛只有一双 ✨",
            subtitle: "照顾好自己",
            gradientColors: [
                Color(red: 1, green: 60/255, blue: 172/255),
                Color(red: 1, green: 107/255, blue: 107/255),
                Color(red: 251/255, green: 191/255, blue: 36/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: "时间线不会跑掉的\n先让眼睛散散步 🍃",
            subtitle: "好的作品需要好的眼睛",
            gradientColors: [
                Color(red: 132/255, green: 204/255, blue: 22/255),
                Color(red: 78/255, green: 205/255, blue: 196/255),
                Color(red: 56/255, green: 189/255, blue: 248/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: "灵感需要休息\n眼睛也是 🌙",
            subtitle: "放空一下，说不定有新想法",
            gradientColors: [
                Color(red: 99/255, green: 102/255, blue: 241/255),
                Color(red: 167/255, green: 139/255, blue: 250/255),
                Color(red: 244/255, green: 114/255, blue: 182/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: "剪辑的节奏很重要\n休息的节奏也是 🎵",
            subtitle: "张弛有度",
            gradientColors: [
                Color(red: 245/255, green: 158/255, blue: 11/255),
                Color(red: 1, green: 107/255, blue: 107/255),
                Color(red: 244/255, green: 114/255, blue: 182/255)
            ],
            isSpecial: false
        ),
    ]

    // MARK: - Sunflower Special Messages (original)

    private let sunflowerSpecialMessages: [ReminderMessage] = [
        ReminderMessage(
            text: "太阳葵也需要\n看看远处的阳光",
            subtitle: "— 来自一个关心你的人",
            gradientColors: [
                Color(red: 251/255, green: 191/255, blue: 36/255),
                Color(red: 245/255, green: 158/255, blue: 11/255),
                Color(red: 1, green: 107/255, blue: 107/255)
            ],
            isSpecial: true
        ),
        ReminderMessage(
            text: "有人帮你晒着阳光\n你先休息一下",
            subtitle: "— ☀️",
            gradientColors: [
                Color(red: 37/255, green: 99/255, blue: 235/255),
                Color(red: 78/255, green: 205/255, blue: 196/255),
                Color(red: 167/255, green: 139/255, blue: 250/255)
            ],
            isSpecial: true
        ),
        ReminderMessage(
            text: "向日葵追太阳\n你也别忘了追光的眼睛",
            subtitle: "— 🌻",
            gradientColors: [
                Color(red: 251/255, green: 191/255, blue: 36/255),
                Color(red: 132/255, green: 204/255, blue: 22/255),
                Color(red: 78/255, green: 205/255, blue: 196/255)
            ],
            isSpecial: true
        ),
    ]

    private init() {}

    private var normalMessages: [ReminderMessage] {
        EditionManager.shared.isSunflower ? sunflowerNormalMessages : genericNormalMessages
    }

    private var specialMessages: [ReminderMessage] {
        EditionManager.shared.isSunflower ? sunflowerSpecialMessages : genericSpecialMessages
    }

    /// Returns the next message. Special messages appear approximately every 5th time.
    func nextMessage() -> ReminderMessage {
        messageIndex += 1

        // Every ~5 reminders, show a special message
        if messageIndex % 5 == 0 {
            return specialMessages.randomElement()!
        }

        // Otherwise rotate through normal messages
        let index = (messageIndex - 1) % normalMessages.count
        return normalMessages[index]
    }

    /// Force a specific message (for testing)
    func getMessage(special: Bool) -> ReminderMessage {
        if special {
            return specialMessages.randomElement()!
        }
        return normalMessages.randomElement()!
    }
}
