import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case chineseSimplified

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return L10n.text("language.option.system")
        case .english:
            return L10n.text("language.option.english")
        case .chineseSimplified:
            return L10n.text("language.option.chineseSimplified")
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .chineseSimplified:
            return "zh-Hans"
        }
    }
}

enum L10n {
    private static let languageKey = "Faraway_AppLanguage"

    static var appLanguage: AppLanguage {
        get {
            let stored = UserDefaults.standard.string(forKey: languageKey)
            return AppLanguage(rawValue: stored ?? "") ?? .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
        }
    }

    static var currentLanguage: AppLanguage {
        if appLanguage == .system {
            if let preferred = Locale.preferredLanguages.first?.lowercased(),
               preferred.hasPrefix("zh") {
                return .chineseSimplified
            }
            return .english
        }
        return appLanguage
    }

    static var selectedLocale: Locale {
        Locale(identifier: currentLanguage.localeIdentifier ?? Locale.current.identifier)
    }

    static func text(_ key: String, _ fallback: String? = nil) -> String {
        localized(key: key, fallback: fallback)
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: localized(key: key), locale: selectedLocale, arguments: args)
    }

    static func localized(key: String, fallback: String? = nil) -> String {
        let table = translations[currentLanguage]?[key] ?? translations[.english]?[key] ?? fallback ?? key
        return table
    }

    static var allTranslationKeys: Set<String> {
        Set(translations.values.flatMap(\.keys))
    }

    static let translations: [AppLanguage: [String: String]] = [
        .english: [
            "language.title": "Language",
            "language.option.system": "System",
            "language.option.english": "English",
            "language.option.chineseSimplified": "Simplified Chinese",
            "app.status.active": "Guarding",
            "app.status.idle": "Standing by",
            "settings.title": "Monitoring Settings",
            "settings.back": "Back",
            "settings.mode.title": "Monitoring Mode",
            "settings.mode.global": "Global",
            "settings.mode.selectApps": "Manual Select",
            "settings.mode.global.desc": "Gentle reminders on a timer, without tracking specific apps.",
            "settings.mode.selectApps.desc.one": "1 app selected",
            "settings.mode.selectApps.desc.many": "%d apps selected",
            "settings.mode.selectApps.desc.none": "Tap to choose the apps you want to monitor.",
            "settings.selectApps.title": "Choose Apps",
            "settings.selectApps.refresh": "Refresh list",
            "settings.selectApps.clear": "Clear All",
            "settings.selectApps.onlyManual": "Works only in Manual Select mode.",
            "settings.selectApps.none": "No running apps right now.",
            "settings.selectApps.known.generic": "Known apps",
            "settings.selectApps.known.sunflower": "Known editing apps",
            "settings.selectApps.all": "All running apps",
            "settings.selectApps.active": "Monitoring",
            "settings.launchAtLogin": "Launch at login",
            "settings.weather.title": "Smart weather copy",
            "settings.weather.subtitle": "Swap reminder text based on local weather.",
            "settings.version": "Version",
            "settings.secret.restore": "Restore Generic Edition",
            "settings.secret.prompt": "Enter secret code",
            "settings.secret.cancel": "Cancel",
            "settings.secret.thanks": "Thank you for keeping Faraway with you",
            "settings.secret.thanks.sunflower": "To the person who taught me to see the sunlight 🌻",
            "settings.loading": "Loading...",
            "settings.quit": "Quit",
            "settings.quit.confirm": "Take care of your eyes. Go look farther away.",
            "settings.quit.keep": "Keep guarding",
            "settings.quit.confirm.sunflower": "Take care of your eyes. Go look at a farther view. 🌻",
            "timer.waiting": "Waiting for a monitored app to start",
            "timer.nextBreak": "Time until the next break",
            "timer.standby": "Standing by",
            "timer.noApp": "No monitored app detected",
            "timer.launchHint.generic": "The timer will start when a monitored app opens.",
            "timer.launchHint.sunflower": "The timer will start when an editing app opens.",
            "timer.mode.global": "Global",
            "timer.mode.custom": "Custom",
            "timer.global.desc": "Timed eye-care reminders",
            "timer.running": "%@ is running",
            "timer.waitingApp": "Waiting for a monitored app to start",
            "stats.breaks": "Breaks",
            "stats.relax": "Relax",
            "stats.guard": "Guard time",
            "footer.restNow": "Rest now",
            "footer.settings": "Settings",
            "footer.quit": "Quit",
            "footer.quit.title": "Take care of your eyes and look farther away",
            "footer.quit.title.sunflower": "Take care of your eyes and look farther away 🌻",
            "footer.quit.exit": "Quit",
            "footer.quit.continue": "Keep guarding",
            "monitor.global.title": "Global",
            "monitor.manual.title": "Manual Select",
            "monitor.global.desc": "Timed reminders for eye care, without tracking specific software.",
            "monitor.manual.desc.one": "1 app selected",
            "monitor.manual.desc.many": "%d apps selected",
            "monitor.manual.desc.none": "Tap to choose an app to monitor.",
            "monitor.selectApps": "Choose App",
            "monitor.selectApps.refresh": "Refresh list",
            "monitor.selectApps.clear": "Clear All",
            "monitor.selectApps.onlyManual": "Works only in Manual Select mode.",
            "monitor.selectApps.none": "No running apps right now.",
            "monitor.known.generic": "Known apps",
            "monitor.known.sunflower": "Known editing apps",
            "monitor.all": "All running apps",
            "monitor.active": "Monitoring",
            "welcome.title": "Welcome",
            "welcome.subtitle": "I am Faraway, and I will remind you to rest every 20 minutes.",
            "welcome.feature": "After opening the app, protection starts automatically.",
            "welcome.finish": "Get started",
            "welcome.next": "Next",
            "daily.title": "Today's Eye-care Report",
            "daily.breaks": "Breaks",
            "daily.relax": "Relax",
            "daily.guard": "Guard time",
            "daily.message": "You worked hard today. Your eyes appreciate every pause.",
            "daily.message.followup": "Remember to rest again tomorrow.",
            "daily.goodnight": "Good night",
            "reminder.countdown": "SEC",
            "reminder.done": "I rested already ✓",
            "reminder.skip": "Skip",
            "reminder.nudge": "Look farther away for a moment. It is good for your eyes.",
            "startup.prompt.title": "Start Faraway at login?",
            "startup.prompt.body": "Choose to launch Faraway automatically at startup so it can remind you to rest.",
            "startup.prompt.enable": "Launch at login",
            "startup.prompt.later": "Not now",
            "mode.global": "Global",
            "mode.manual": "Manual Select",
            "mode.global.short": "Global guarding",
            "mode.manual.short": "Custom",
            "mode.waiting": "Waiting for monitored app",
            "mode.running": "Running",
            "mode.all": "All apps",
            "mode.appsSelected.one": "1 app",
            "mode.appsSelected.many": "%d apps",
            "mode.current.none": "Waiting for monitored app to start",
            "mode.current.global": "Timed eye-care reminders",
            "mode.current.custom": "Custom monitoring",
            "weather.rain": "Rainy days are good for taking it slow.",
            "weather.clear": "You can recharge by getting some sunlight today ☀️",
            "weather.cloudy": "The sun will come back ☀️",
            "date.late.generic": "It is late. Tomorrow can be busy too.",
            "date.late.sunflower": "It is late. Video edits can wait until tomorrow.",
            "date.late.common": "It is late. Your eyes matter more than the deadline.",
            "date.late.sleep": "Go to bed early so you can see tomorrow's sun.",
            "date.sunflower.day": "Sunflower, get a little more sunlight today 🌻",
            "date.birthday": "Happy birthday, Sunflower 🎂🌻",
            "date.newyear.generic": "Happy New Year 🌻",
            "date.newyear.sunflower": "Happy New Year, Sunflower 🌻",
            "date.install.one": "We have been together for a year",
            "date.install.two": "Still here",
            "date.install.many": "We have been together for %d years",
            "milestone.one.generic": "First time, a good start",
            "milestone.one.sunflower": "First time, a good start 🌻",
            "milestone.50": "50 looks into the distance, your eyes say thanks",
            "milestone.200": "200 times already, that is a good habit",
            "milestone.500": "500 glances into the distance, the views must have been beautiful",
            "milestone.1000.generic": "A thousand looks into the distance",
            "milestone.1000.sunflower": "A thousand looks into the distance 🌻",
            "milestone.2000.generic": "Still using it, nice",
            "milestone.2000.sunflower": "Still using it. Someone is very happy 🌻",
            "milestone.5000": "It has been a long time. Go look even farther away",
            "milestone.week": "One full week, great job",
            "milestone.month": "A month in, eye care is becoming a habit",
            "milestone.100.generic": "100 days 🌻",
            "milestone.100.sunflower": "100 days, impressive",
            "milestone.365": "A whole year. Faraway is happy to be with you",
            "reminder.generic.one": "Look out the window\nThe view is waiting for you 🌿",
            "reminder.generic.one.subtitle": "Let your eyes travel for 20 seconds",
            "reminder.generic.two": "Your eyes worked hard\nLet them breathe for 20 seconds ☁️",
            "reminder.generic.two.subtitle": "Take a breath and look far away",
            "reminder.generic.three": "The world is bigger than the screen\nLook up 💜",
            "reminder.generic.three.subtitle": "There is a nice view outside",
            "reminder.generic.four": "Work can wait a moment\nYou only have one pair of eyes ✨",
            "reminder.generic.four.subtitle": "Take care of yourself",
            "reminder.generic.five": "Things will not run away\nLet your eyes take a walk 🍃",
            "reminder.generic.five.subtitle": "Good state needs good eyes",
            "reminder.generic.six": "Ideas need rest\nSo do your eyes 🌙",
            "reminder.generic.six.subtitle": "Let your mind drift a little",
            "reminder.generic.seven": "Rhythm matters at work\nRest rhythm matters too 🎵",
            "reminder.generic.seven.subtitle": "Balance is everything",
            "reminder.special.one": "You need this too\nLook at the sunlight far away",
            "reminder.special.one.subtitle": "From Faraway",
            "reminder.special.two": "The sunlight is waiting for you\nRest first",
            "reminder.special.two.subtitle": "☀️",
            "reminder.special.three": "On the road to light\nDo not forget your eyes",
            "reminder.special.three.subtitle": "✨",
            "reminder.sunflower.one": "Sunflowers also need\nA look at the sunlight",
            "reminder.sunflower.one.subtitle": "From someone who cares about you",
            "reminder.sunflower.two": "Someone is holding the sunlight for you\nYou can rest now",
            "reminder.sunflower.two.subtitle": "☀️",
            "reminder.sunflower.three": "Sunflowers follow the sun\nYou should not forget your eyes either",
            "reminder.sunflower.three.subtitle": "🌻",
            "reminder.editing.one": "Video can wait a bit\nYou only have one pair of eyes ✨",
            "reminder.editing.one.subtitle": "Take care of yourself",
            "reminder.editing.two": "The timeline will still be there\nLet your eyes take a walk 🍃",
            "reminder.editing.two.subtitle": "Great work needs great eyes",
            "reminder.editing.three": "Editing rhythm matters\nRest rhythm matters too 🎵",
            "reminder.editing.three.subtitle": "Balance is everything",
            "reminder.gentle.sunflower": "Take another look at the distance. It is good for your eyes 🌻",
            "reminder.gentle": "Take another look at the distance. It is good for your eyes",
        ],
        .chineseSimplified: [
            "language.title": "语言",
            "language.option.system": "跟随系统",
            "language.option.english": "English",
            "language.option.chineseSimplified": "简体中文",
            "app.status.active": "守护中",
            "app.status.idle": "待机中",
            "settings.title": "监测设置",
            "settings.back": "返回",
            "settings.mode.title": "监测模式",
            "settings.mode.global": "全局",
            "settings.mode.selectApps": "手动选择",
            "settings.mode.global.desc": "无论是否打开软件，定时提醒护眼。",
            "settings.mode.selectApps.desc.one": "已选择 1 个应用",
            "settings.mode.selectApps.desc.many": "已选择 %d 个应用",
            "settings.mode.selectApps.desc.none": "点击选择要监测的 App。",
            "settings.selectApps.title": "选择 App",
            "settings.selectApps.refresh": "刷新列表",
            "settings.selectApps.clear": "全清",
            "settings.selectApps.onlyManual": "仅在「手动选择」模式下生效。",
            "settings.selectApps.none": "当前没有正在运行的 App。",
            "settings.selectApps.known.generic": "已知的常用软件",
            "settings.selectApps.known.sunflower": "已知的剪辑软件",
            "settings.selectApps.all": "正在运行的所有 App",
            "settings.selectApps.active": "监测中",
            "settings.launchAtLogin": "开机启动",
            "settings.weather.title": "智能天气文案",
            "settings.weather.subtitle": "根据当地天气自动更换护眼文案。",
            "settings.version": "版本",
            "settings.secret.restore": "恢复通用版",
            "settings.secret.prompt": "输入暗号",
            "settings.secret.cancel": "取消",
            "settings.secret.thanks": "感谢你一直在用 Faraway",
            "settings.secret.thanks.sunflower": "给那个教会我看见阳光的人 🌻",
            "settings.loading": "加载中...",
            "settings.quit": "退出",
            "settings.quit.confirm": "照顾好眼睛，去看更远的风景吧",
            "settings.quit.keep": "继续守护",
            "settings.quit.confirm.sunflower": "照顾好眼睛。去看更远的风景吧 🌻",
            "timer.waiting": "等待监测应用启动",
            "timer.nextBreak": "距离下次休息",
            "timer.standby": "待机中",
            "timer.noApp": "未检测到监测应用",
            "timer.launchHint.generic": "打开监测应用后自动启动。",
            "timer.launchHint.sunflower": "打开剪辑软件后自动启动。",
            "timer.mode.global": "全局",
            "timer.mode.custom": "定制",
            "timer.global.desc": "定时提醒护眼",
            "timer.running": "%@ 正在运行",
            "timer.waitingApp": "等待监测应用启动",
            "stats.breaks": "次休息",
            "stats.relax": "分钟放松",
            "stats.guard": "守护时长",
            "footer.restNow": "立即休息",
            "footer.settings": "设置",
            "footer.quit": "退出",
            "footer.quit.title": "照顾好眼睛，去看更远的风景吧",
            "footer.quit.title.sunflower": "照顾好眼睛。去看更远的风景吧 🌻",
            "footer.quit.exit": "退出",
            "footer.quit.continue": "继续守护",
            "monitor.global.title": "全局",
            "monitor.manual.title": "手动选择",
            "monitor.global.desc": "无论是否打开软件，定时提醒护眼。",
            "monitor.manual.desc.one": "已选择 1 个应用",
            "monitor.manual.desc.many": "已选择 %d 个应用",
            "monitor.manual.desc.none": "点击选择要监测的 App。",
            "monitor.selectApps": "选择 App",
            "monitor.selectApps.refresh": "刷新列表",
            "monitor.selectApps.clear": "全清",
            "monitor.selectApps.onlyManual": "仅在「手动选择」模式下生效。",
            "monitor.selectApps.none": "当前没有正在运行的 App。",
            "monitor.known.generic": "已知的常用软件",
            "monitor.known.sunflower": "已知的剪辑软件",
            "monitor.all": "正在运行的所有 App",
            "monitor.active": "监测中",
            "welcome.title": "你好",
            "welcome.subtitle": "我是 Faraway，每 20 分钟提醒你休息一下。",
            "welcome.feature": "打开应用后，自动开始守护你的眼睛。",
            "welcome.finish": "开始使用",
            "welcome.next": "下一步",
            "daily.title": "今日护眼报告",
            "daily.breaks": "次休息",
            "daily.relax": "分钟放松",
            "daily.guard": "守护时长",
            "daily.message": "今天辛苦了，眼睛感谢你每一次的停下来 ✦",
            "daily.message.followup": "明天也要记得休息哦",
            "daily.goodnight": "晚安",
            "reminder.countdown": "秒",
            "reminder.done": "我休息好了 ✓",
            "reminder.skip": "跳过",
            "reminder.nudge": "再看一会儿远处嘛～ 对眼睛好",
            "startup.prompt.title": "开机启动 Faraway？",
            "startup.prompt.body": "选择开机自动启动 Faraway，以便更好地提醒您休息。",
            "startup.prompt.enable": "开机启动",
            "startup.prompt.later": "暂不",
            "mode.global": "全局",
            "mode.manual": "手动选择",
            "mode.global.short": "全局守护",
            "mode.manual.short": "定制",
            "mode.waiting": "等待监测应用",
            "mode.running": "运行中",
            "mode.all": "全部应用",
            "mode.appsSelected.one": "1 个应用",
            "mode.appsSelected.many": "%d 个应用",
            "mode.current.none": "等待监测应用启动",
            "mode.current.global": "定时提醒护眼",
            "mode.current.custom": "定制监测",
            "weather.rain": "下雨的日子，适合慢一点",
            "weather.clear": "今天可以去晒着阳光充充电 ☀️",
            "weather.cloudy": "阳光会回来的 ☀️",
            "date.late.generic": "这么晚了，明天再忙。",
            "date.late.sunflower": "这么晚了，视频明天再剪 🌙",
            "date.late.common": "夜很深了，眼睛比 deadline 重要。",
            "date.late.sleep": "别熬了，要早点睡才能晒到明天的太阳 🌻",
            "date.sunflower.day": "太阳葵，今天多晒一会儿阳光 🌻",
            "date.birthday": "生日快乐，太阳葵 🎂🌻",
            "date.newyear.generic": "新年快乐 🌻",
            "date.newyear.sunflower": "新年快乐，太阳葵 🌻",
            "date.install.one": "陪你一年了",
            "date.install.two": "还在呢",
            "date.install.many": "陪你%d年了",
            "milestone.one.generic": "第一次，一个好的开始",
            "milestone.one.sunflower": "第一次，一个好的开始 🌻",
            "milestone.50": "50次远眺，眼睛在说谢谢",
            "milestone.200": "200次了，已经是一个好习惯",
            "milestone.500": "看了500次远方，你看过的风景一定很美",
            "milestone.1000.generic": "一千次远眺",
            "milestone.1000.sunflower": "一千次远眺 🌻",
            "milestone.2000.generic": "还在用着啊，真好",
            "milestone.2000.sunflower": "还在用着啊。有人很高兴 🌻",
            "milestone.5000": "这么久了。去看更远的地方吧",
            "milestone.week": "连续一周了，真棒",
            "milestone.month": "一个月，护眼已经成为你的习惯了",
            "milestone.100.generic": "100天 🌻",
            "milestone.100.sunflower": "100天，了不起",
            "milestone.365": "一整年了。这个App很开心陪着你",
            "reminder.generic.one": "看看窗外吧\n远处的风景在等你 🌿",
            "reminder.generic.one.subtitle": "让眼睛去旅行 20 秒",
            "reminder.generic.two": "眼睛辛苦了\n让它呼吸 20 秒 ☁️",
            "reminder.generic.two.subtitle": "深呼吸，看远方",
            "reminder.generic.three": "世界不止屏幕这么大\n抬头看看 💜",
            "reminder.generic.three.subtitle": "窗外有好风景",
            "reminder.generic.four": "工作可以晚一点\n眼睛只有一双 ✨",
            "reminder.generic.four.subtitle": "照顾好自己",
            "reminder.generic.five": "事情不会跑掉的\n先让眼睛散散步 🍃",
            "reminder.generic.five.subtitle": "好的状态需要好的眼睛",
            "reminder.generic.six": "灵感需要休息\n眼睛也是 🌙",
            "reminder.generic.six.subtitle": "放空一下，说不定有新想法",
            "reminder.generic.seven": "工作的节奏很重要\n休息的节奏也是 🎵",
            "reminder.generic.seven.subtitle": "张弛有度",
            "reminder.special.one": "你也需要\n看看远处的阳光",
            "reminder.special.one.subtitle": "— 来自 Faraway",
            "reminder.special.two": "阳光在等你\n先休息一下",
            "reminder.special.two.subtitle": "— ☀️",
            "reminder.special.three": "追光的路上\n别忘了你的眼睛",
            "reminder.special.three.subtitle": "— ✨",
            "reminder.sunflower.one": "太阳葵也需要\n看看远处的阳光",
            "reminder.sunflower.one.subtitle": "— 来自一个关心你的人",
            "reminder.sunflower.two": "有人帮你晒着阳光\n你先休息一下",
            "reminder.sunflower.two.subtitle": "— ☀️",
            "reminder.sunflower.three": "向日葵追太阳\n你也别忘了追光的眼睛",
            "reminder.sunflower.three.subtitle": "— 🌻",
            "reminder.editing.one": "视频可以晚一点\n眼睛只有一双 ✨",
            "reminder.editing.one.subtitle": "照顾好自己",
            "reminder.editing.two": "时间线不会跑掉的\n先让眼睛散散步 🍃",
            "reminder.editing.two.subtitle": "好的作品需要好的眼睛",
            "reminder.editing.three": "剪辑的节奏很重要\n休息的节奏也是 🎵",
            "reminder.editing.three.subtitle": "张弛有度",
            "reminder.gentle.sunflower": "再看一会儿远处嘛～ 对眼睛好 🌻",
            "reminder.gentle": "再看一会儿远处嘛～ 对眼睛好",
        ]
    ]
}

enum AppInfo {
    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Faraway"
    }

    static var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.1"
    }
}
