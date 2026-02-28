import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appMonitor: AppMonitor
    @Binding var isPresented: Bool
    @State private var refreshTrigger = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { isPresented = false }) {
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

                Color.clear.frame(width: 40)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: NSColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)))

            // Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    // Mode Selection
                    modeSection

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // App Selection (only in selectApps mode)
                    if appMonitor.monitoringMode == .selectApps {
                        appSelectionSection
                    }
                }
                .padding(16)
            }
        }
        .background(Color(nsColor: NSColor(red: 0.04, green: 0.04, blue: 0.1, alpha: 1)))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appMonitor.refreshRunningApps()
                refreshTrigger.toggle()
            }
        }
    }

    // MARK: - Mode Section

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("监测模式")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            ForEach(MonitoringMode.allCases, id: \.self) { mode in
                modeButton(mode)
            }

            Text(appMonitor.monitoringMode.description)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, 4)
        }
    }

    private func modeButton(_ mode: MonitoringMode) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                let wasDifferent = appMonitor.monitoringMode != mode
                appMonitor.monitoringMode = mode
                if mode == .selectApps && wasDifferent {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        appMonitor.refreshRunningApps()
                        refreshTrigger.toggle()
                        if appMonitor.selectedApps.isEmpty {
                            for bundleId in appMonitor.allAvailableApps.keys {
                                appMonitor.selectedApps.insert(bundleId)
                            }
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

                    Text(modeDescriptionText(mode))
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
                    ? Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.15)
                    : Color.white.opacity(0.05)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        appMonitor.monitoringMode == mode
                            ? Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.3)
                            : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func modeDescriptionText(_ mode: MonitoringMode) -> String {
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
                        refreshTrigger.toggle()
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
