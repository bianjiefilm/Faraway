import SwiftUI
import ServiceManagement

struct StatusBarView: View {
    @EnvironmentObject var appMonitor: AppMonitor
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var sessionTracker: SessionTracker

    @State private var showSettings = false
    @State private var isExpanded = false
    @State private var showQuitAlert = false
    @State private var launchAtLogin = false
    @AppStorage("isWeatherEnabled") private var isWeatherEnabled = false
    
    @StateObject private var weatherManager = WeatherManager.shared
    @StateObject private var milestoneManager = MilestoneManager.shared
    @StateObject private var dateManager = DateManager.shared

    private func activeMessage(defaultMsg: String) -> String {
        if let milestone = milestoneManager.currentMilestoneMessage {
            return milestone
        }
        if let dateMsg = dateManager.specialDateMessage {
            return dateMsg
        }
        if let weather = weatherManager.weatherMessage {
            return weather
        }
        return defaultMsg
    }

    private func hasReachedOneYear() -> Bool {
        if let installDateString = UserDefaults.standard.string(forKey: "InstallDateString") {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            if let installDate = df.date(from: installDateString) {
                let years = Calendar.current.dateComponents([.year], from: installDate, to: Date()).year ?? 0
                return years >= 1
            }
        }
        return false
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Header
                headerSection

                Divider()
                    .background(Color.white.opacity(0.06))

                // Content based on mode
                if showSettings {
                    settingsContent
                } else {
                    mainContent
                }
            }
            .frame(width: 300, height: 480, alignment: .top)
            .background(Color(nsColor: NSColor(red: 0.04, green: 0.04, blue: 0.1, alpha: 1)))
            .onAppear {
                print("【布局日志】StatusBarView 已加载。测得边界尺寸: \(geo.size)")
                DateManager.shared.evaluateDates()
            }
        }
        .frame(width: 300, height: 480)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(appMonitor.isEditingAppActive
                          ? Color(red: 251/255, green: 191/255, blue: 36/255)  // Sunflower - active
                          : Color.white.opacity(0.15))
                    .frame(width: 6, height: 6)
                    .shadow(color: appMonitor.isEditingAppActive
                            ? Color(red: 251/255, green: 191/255, blue: 36/255).opacity(0.6)
                            : .clear,
                            radius: 4)

                Text(appMonitor.isEditingAppActive ? "守护中" : "待机中")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Text("Faraway")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            
            // Timer section
            timerSection
            
            Spacer(minLength: 0)

            VStack(spacing: 0) {
                // Card content: Active App & Stats
                VStack(spacing: 0) {
                    activeAppSection
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.horizontal, 16)
                    
                    todayStatsSection
                }
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                
                Spacer(minLength: 24)

                // Footer actions (Floating)
                footerSection
            }
        }
        .frame(height: 480 - 45, alignment: .top)
    }

    // MARK: - Settings Content

    @State private var isLoadingApps = false

    private var settingsContent: some View {
        VStack(spacing: 0) {
            // Settings Header with back button
            HStack {
                Button(action: {
                    showSettings = false
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                        Text("返回")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)

                Spacer()

                Text("监测设置")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Color.clear.frame(width: 40, height: 1) // FIXED BUG: previously this was .frame(width: 40) which expands vertically infinitely!
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: NSColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)))

            Divider()
                .background(Color.white.opacity(0.1))

            // Loading overlay & Content
            ZStack {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Mode Selection
                        settingsModeSection

                        Divider()
                            .background(Color.white.opacity(0.1))

                        // App Selection (only in selectApps mode)
                        if appMonitor.monitoringMode == .selectApps {
                            appSelectionSection
                        }
                    }
                    .padding(16)
                    .opacity(isLoadingApps ? 0.3 : 1.0) // Dim content while loading

                    // Version and Login Toggle
                    VStack(spacing: 12) {
                        Divider()
                            .background(Color.white.opacity(0.1))

                        // Login Item Toggle
                        HStack {
                            Text("开机启动")
                                .font(.system(size: 13))
                                .foregroundColor(.white)

                            Spacer()

                            Toggle("", isOn: $launchAtLogin)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 251/255, green: 191/255, blue: 36/255)))
                                .scaleEffect(0.8)
                                .onChange(of: launchAtLogin) { newValue in
                                    toggleLoginItem(enabled: newValue)
                                }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            
                        // Weather Context Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("智能天气文案")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                Text("根据当地天气自动更换护眼文案")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.35))
                            }

                            Spacer()

                            Toggle("", isOn: $isWeatherEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 251/255, green: 191/255, blue: 36/255)))
                                .scaleEffect(0.8)
                                .onChange(of: isWeatherEnabled) { newValue in
                                    if newValue {
                                        weatherManager.requestPermissionAndFetch()
                                    } else {
                                        weatherManager.disableWeather()
                                    }
                                }
                        }

                        // Version Info
                        HStack {
                            Text("版本")
                                .font(.system(size: 13))
                                .foregroundColor(.white)

                            Spacer()

                            Text("1.0.9")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }

                        if hasReachedOneYear() {
                            Text("给那个教会我看见阳光的人 🌻")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.2))
                                .padding(.top, 16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .opacity(isLoadingApps ? 0.3 : 1.0)
                }

                if isLoadingApps {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 251/255, green: 191/255, blue: 36/255)))
                            .scaleEffect(1.2)

                        Text("加载中...")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: NSColor(red: 0.04, green: 0.04, blue: 0.1, alpha: 0.5))) // Semi-transparent background
                }
            }
            .background(Color(nsColor: NSColor(red: 0.04, green: 0.04, blue: 0.1, alpha: 1)))
        }
        .frame(height: 480 - 45, alignment: .top)
        .background(Color(nsColor: NSColor(red: 0.04, green: 0.04, blue: 0.1, alpha: 1)))
        .onAppear {
            checkLoginStatus()
        }
    }

    // MARK: - Login Item

    private func checkLoginStatus() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func toggleLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to toggle login item: \(error)")
            }
        }
    }

    private var timerSection: some View {
        VStack(spacing: 6) {
            if appMonitor.isEditingAppActive {
                Text(timerManager.formattedTimeRemaining)
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255))
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3), radius: 8)
                    .padding(.top, 16)

                Text(appMonitor.isEditingAppActive ? activeMessage(defaultMsg: "距离下次休息") : activeMessage(defaultMsg: "等待监测应用启动"))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.25))
                    .padding(.bottom, 12)
                    .animation(.easeInOut, value: activeMessage(defaultMsg: "距离下次休息"))
            } else {
                VStack(spacing: 12) {
                    // Empty state illustration
                    Image("空状态待机画面")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                        .opacity(0.8)

                    Text("待机中")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))

                    Text("未检测到剪辑软件")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.25))

                    Text("打开剪辑软件后自动启动")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.15))
                }
                .padding(.vertical, 24)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Active App

    private var activeAppSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(appMonitor.monitoringMode == .global ? "全局" : "定制")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(appMonitor.monitoringMode == .global
                        ? Color(red: 167/255, green: 139/255, blue: 250/255)  // Lavender - Global
                        : Color(red: 251/255, green: 191/255, blue: 36/255))  // Sunflower - Custom
                    .foregroundColor(Color(red: 0.04, green: 0.04, blue: 0.1))
                    .cornerRadius(4)

                if appMonitor.monitoringMode == .global {
                    Text(activeMessage(defaultMsg: "定时提醒护眼"))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                        .animation(.easeInOut, value: activeMessage(defaultMsg: "定时提醒护眼"))
                } else if let activeApp = appMonitor.currentEditingApp {
                    Text("\(activeApp) 正在运行")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255))
                } else {
                    Text(activeMessage(defaultMsg: "等待监测应用启动"))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                        .animation(.easeInOut, value: activeMessage(defaultMsg: "等待监测应用启动"))
                }

                Spacer()

                if appMonitor.monitoringMode == .selectApps && !appMonitor.selectedApps.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 2) {
                            Text("\(appMonitor.selectedApps.count) 个应用")
                                .font(.system(size: 10))
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }

            if appMonitor.monitoringMode == .selectApps && isExpanded && !appMonitor.selectedApps.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(appMonitor.selectedApps), id: \.self) { bundleId in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(appMonitor.currentEditingApp == appMonitor.displayName(for: bundleId)
                                    ? Color(red: 78/255, green: 205/255, blue: 196/255)
                                    : Color.white.opacity(0.2))
                                .frame(width: 6, height: 6)

                            Text(appMonitor.displayName(for: bundleId))
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.7))

                            Spacer()

                            if appMonitor.currentEditingApp == appMonitor.displayName(for: bundleId) {
                                Text("运行中")
                                    .font(.system(size: 9))
                                    .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Today Stats

    private var todayStatsSection: some View {
        HStack(spacing: 0) {
            statCell(
                value: "\(sessionTracker.todayBreakCount)",
                label: "次休息"
            )
            statCell(
                value: String(format: "%.1f", Double(sessionTracker.todayTotalRelaxSeconds) / 60.0),
                label: "分钟放松"
            )
            statCell(
                value: String(format: "%.1f", sessionTracker.todayTotalGuardMinutes / 60.0) + "h",
                label: "守护时长"
            )
        }
        .padding(.vertical, 16)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Button(action: {
                TimerManager.shared.triggerReminderNow()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                        .font(.system(size: 10))
                    Text("立即休息")
                        .font(.system(size: 11))
                }
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: {
                showSettings = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 10))
                    Text("设置")
                        .font(.system(size: 11))
                }
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Button(action: {
                showQuitAlert = true
            }) {
                Text("退出")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }
            .buttonStyle(.plain)
            .alert(isPresented: $showQuitAlert) {
                Alert(
                    title: Text("照顾好眼睛。去看更远的风景吧 🌻"),
                    primaryButton: .destructive(Text("退出")) {
                        NSApp.terminate(nil)
                    },
                    secondaryButton: .cancel(Text("继续守护"))
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Settings Mode Section

    private var settingsModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("监测模式")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            ForEach(MonitoringMode.allCases, id: \.self) { mode in
                settingsModeButton(mode)
            }

            Text(appMonitor.monitoringMode.description)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, 4)
        }
    }

    private func settingsModeButton(_ mode: MonitoringMode) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                let wasDifferent = appMonitor.monitoringMode != mode
                appMonitor.monitoringMode = mode
                if mode == .selectApps && wasDifferent {
                    // Show loading state
                    isLoadingApps = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        appMonitor.refreshRunningApps()
                        if appMonitor.selectedApps.isEmpty {
                            for bundleId in appMonitor.allAvailableApps.keys {
                                appMonitor.selectedApps.insert(bundleId)
                            }
                        }
                        // Hide loading after a short delay to show the animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoadingApps = false
                        }
                    }
                }
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)

                    Text(settingsModeDescriptionText(mode))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.35))
                }

                Spacer()

                if appMonitor.monitoringMode == mode {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255))
                }
            }
            .padding(12)
            .background(
                appMonitor.monitoringMode == mode
                    ? Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.25)
                    : Color.white.opacity(0.05)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        appMonitor.monitoringMode == mode
                            ? Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.8)
                            : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func settingsModeDescriptionText(_ mode: MonitoringMode) -> String {
        switch mode {
        case .global:
            return "定时提醒护眼，不监测特定软件"
        case .selectApps:
            let count = appMonitor.selectedApps.count
            return count > 0 ? "已选择 \(count) 个应用" : "点击选择要监测的 App"
        }
    }

    // MARK: - App Selection Section

    private var appSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("选择 App")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        appMonitor.refreshRunningApps()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help("刷新列表")

                if !appMonitor.selectedApps.isEmpty {
                    Button("全清") {
                        appMonitor.selectedApps.removeAll()
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .buttonStyle(.plain)
                }
            }

            Text("仅在「手动选择」模式下生效")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))
                .padding(.bottom, 4)

            if appMonitor.runningApplications.isEmpty {
                Text("当前没有正在运行的 App")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                let knownRunningApps = appMonitor.runningApplications.filter { appMonitor.allAvailableApps[$0.bundleId] != nil }

                if !knownRunningApps.isEmpty {
                    Text("已知的剪辑软件")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.bottom, 4)

                    ForEach(knownRunningApps, id: \.bundleId) { app in
                        appToggleRow(bundleId: app.bundleId, name: appMonitor.displayName(for: app.bundleId))
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.vertical, 8)
                }

                Text("正在运行的所有 App")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 4)

                ForEach(appMonitor.runningApplications, id: \.bundleId) { app in
                    appToggleRow(bundleId: app.bundleId, name: app.name)
                }
            }
        }
    }

    private func appToggleRow(bundleId: String, name: String) -> some View {
        Button(action: {
            if appMonitor.selectedApps.contains(bundleId) {
                appMonitor.selectedApps.remove(bundleId)
            } else {
                appMonitor.selectedApps.insert(bundleId)
            }
        }) {
            HStack {
                Circle()
                    .fill(appMonitor.selectedApps.contains(bundleId)
                        ? Color(red: 78/255, green: 205/255, blue: 196/255)
                        : Color.white.opacity(0.1))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(appMonitor.selectedApps.contains(bundleId)
                                    ? Color.clear
                                    : Color.white.opacity(0.2),
                                    lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.04, green: 0.04, blue: 0.1))
                            .opacity(appMonitor.selectedApps.contains(bundleId) ? 1 : 0)
                    )

                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                if appMonitor.selectedApps.contains(bundleId) {
                    Text("监测中")
                        .font(.system(size: 9))
                        .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.03))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
