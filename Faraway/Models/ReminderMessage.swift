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
            text: L10n.text("reminder.generic.one"),
            subtitle: L10n.text("reminder.generic.one.subtitle"),
            gradientColors: [
                Color(red: 1, green: 107/255, blue: 107/255),
                Color(red: 1, green: 142/255, blue: 83/255),
                Color(red: 1, green: 230/255, blue: 109/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: L10n.text("reminder.generic.two"),
            subtitle: L10n.text("reminder.generic.two.subtitle"),
            gradientColors: [
                Color(red: 78/255, green: 205/255, blue: 196/255),
                Color(red: 68/255, green: 176/255, blue: 158/255),
                Color(red: 56/255, green: 189/255, blue: 248/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: L10n.text("reminder.generic.three"),
            subtitle: L10n.text("reminder.generic.three.subtitle"),
            gradientColors: [
                Color(red: 167/255, green: 139/255, blue: 250/255),
                Color(red: 129/255, green: 140/255, blue: 248/255),
                Color(red: 99/255, green: 102/255, blue: 241/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: L10n.text("reminder.generic.four"),
            subtitle: L10n.text("reminder.generic.four.subtitle"),
            gradientColors: [
                Color(red: 1, green: 60/255, blue: 172/255),
                Color(red: 1, green: 107/255, blue: 107/255),
                Color(red: 251/255, green: 191/255, blue: 36/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: L10n.text("reminder.generic.five"),
            subtitle: L10n.text("reminder.generic.five.subtitle"),
            gradientColors: [
                Color(red: 132/255, green: 204/255, blue: 22/255),
                Color(red: 78/255, green: 205/255, blue: 196/255),
                Color(red: 56/255, green: 189/255, blue: 248/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: L10n.text("reminder.generic.six"),
            subtitle: L10n.text("reminder.generic.six.subtitle"),
            gradientColors: [
                Color(red: 99/255, green: 102/255, blue: 241/255),
                Color(red: 167/255, green: 139/255, blue: 250/255),
                Color(red: 244/255, green: 114/255, blue: 182/255)
            ],
            isSpecial: false
        ),
        ReminderMessage(
            text: L10n.text("reminder.generic.seven"),
            subtitle: L10n.text("reminder.generic.seven.subtitle"),
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
            text: L10n.text("reminder.special.one"),
            subtitle: L10n.text("reminder.special.one.subtitle"),
            gradientColors: [
                Color(red: 251/255, green: 191/255, blue: 36/255),
                Color(red: 245/255, green: 158/255, blue: 11/255),
                Color(red: 1, green: 107/255, blue: 107/255)
            ],
            isSpecial: true
        ),
        ReminderMessage(
            text: L10n.text("reminder.special.two"),
            subtitle: L10n.text("reminder.special.two.subtitle"),
            gradientColors: [
                Color(red: 37/255, green: 99/255, blue: 235/255),
                Color(red: 78/255, green: 205/255, blue: 196/255),
                Color(red: 167/255, green: 139/255, blue: 250/255)
            ],
            isSpecial: true
        ),
        ReminderMessage(
            text: L10n.text("reminder.special.three"),
            subtitle: L10n.text("reminder.special.three.subtitle"),
            gradientColors: [
                Color(red: 251/255, green: 191/255, blue: 36/255),
                Color(red: 132/255, green: 204/255, blue: 22/255),
                Color(red: 78/255, green: 205/255, blue: 196/255)
            ],
            isSpecial: true
        ),
    ]

    // MARK: - Sunflower Normal Messages
    // Sunflower edition reuses the generic messages plus the video-editing themed ones
    private var sunflowerNormalMessages: [ReminderMessage] {
        genericNormalMessages.dropLast(3) + [
        ReminderMessage(
                text: L10n.text("reminder.editing.one"),
                subtitle: L10n.text("reminder.editing.one.subtitle"),
                gradientColors: [
                    Color(red: 1, green: 60/255, blue: 172/255),
                    Color(red: 1, green: 107/255, blue: 107/255),
                    Color(red: 251/255, green: 191/255, blue: 36/255)
                ],
                isSpecial: false
            ),
        ReminderMessage(
                text: L10n.text("reminder.editing.two"),
                subtitle: L10n.text("reminder.editing.two.subtitle"),
                gradientColors: [
                    Color(red: 132/255, green: 204/255, blue: 22/255),
                    Color(red: 78/255, green: 205/255, blue: 196/255),
                    Color(red: 56/255, green: 189/255, blue: 248/255)
                ],
                isSpecial: false
            ),
        ReminderMessage(
                text: L10n.text("reminder.editing.three"),
                subtitle: L10n.text("reminder.editing.three.subtitle"),
                gradientColors: [
                    Color(red: 245/255, green: 158/255, blue: 11/255),
                    Color(red: 1, green: 107/255, blue: 107/255),
                    Color(red: 244/255, green: 114/255, blue: 182/255)
                ],
                isSpecial: false
            ),
        ]
    }

    // MARK: - Sunflower Special Messages (original)

    private let sunflowerSpecialMessages: [ReminderMessage] = [
        ReminderMessage(
            text: L10n.text("reminder.sunflower.one"),
            subtitle: L10n.text("reminder.sunflower.one.subtitle"),
            gradientColors: [
                Color(red: 251/255, green: 191/255, blue: 36/255),
                Color(red: 245/255, green: 158/255, blue: 11/255),
                Color(red: 1, green: 107/255, blue: 107/255)
            ],
            isSpecial: true
        ),
        ReminderMessage(
            text: L10n.text("reminder.sunflower.two"),
            subtitle: L10n.text("reminder.sunflower.two.subtitle"),
            gradientColors: [
                Color(red: 37/255, green: 99/255, blue: 235/255),
                Color(red: 78/255, green: 205/255, blue: 196/255),
                Color(red: 167/255, green: 139/255, blue: 250/255)
            ],
            isSpecial: true
        ),
        ReminderMessage(
            text: L10n.text("reminder.sunflower.three"),
            subtitle: L10n.text("reminder.sunflower.three.subtitle"),
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
