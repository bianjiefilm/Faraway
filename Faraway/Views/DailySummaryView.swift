import SwiftUI

struct DailySummaryView: View {
    let breakCount: Int
    let totalRelaxSeconds: Int
    let guardHours: Double
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showStats = false
    @State private var showMessage = false
    @State private var sunflowerRotation: Double = -5

    var body: some View {
        ZStack {
            // Background image - scaled to fit
            Image("护眼日报卡片背景")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(1.2)
                .ignoresSafeArea()

            // Semi-transparent overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            // Content - centered and scrollable if needed
            VStack(spacing: 0) {
                Spacer()

                // Title with warm styling
                HStack(spacing: 8) {
                    Text(EditionManager.shared.isSunflower ? "🌻" : "✦")
                        .font(.system(size: 18))
                        .rotationEffect(.degrees(sunflowerRotation))
                        .animation(
                            .easeInOut(duration: 3).repeatForever(autoreverses: true),
                            value: sunflowerRotation
                        )

                    Text("今日护眼报告")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .tracking(2)
                        .textCase(.uppercase)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.spring(response: 0.8).delay(0.2), value: showContent)
                .padding(.bottom, 24)

                // Stats
                HStack(spacing: 30) {
                    statItem(
                        value: "\(breakCount)",
                        label: "次休息"
                    )
                    statItem(
                        value: String(format: "%.1f", Double(totalRelaxSeconds) / 60.0),
                        label: "分钟放松"
                    )
                    statItem(
                        value: String(format: "%.1f", guardHours) + "h",
                        label: "守护时长"
                    )
                }
                .opacity(showStats ? 1 : 0)
                .offset(y: showStats ? 0 : 20)
                .animation(.spring(response: 0.8).delay(0.5), value: showStats)
                .padding(.bottom, 24)

                // Warm message
                VStack(spacing: 8) {
                    Text("今天辛苦了，眼睛感谢你每一次的停下来 ✦")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    Text("明天也要记得休息哦")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .opacity(showMessage ? 1 : 0)
                .offset(y: showMessage ? 0 : 20)
                .animation(.spring(response: 0.8).delay(0.8), value: showMessage)
                .padding(.bottom, 20)

                // Close button - always visible at bottom
                Button(action: onDismiss) {
                    Text("晚安 ✦")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)
                .opacity(showMessage ? 1 : 0)
                .animation(.easeIn.delay(1.0), value: showMessage)

                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            sunflowerRotation = 5
            withAnimation {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { showStats = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation { showMessage = true }
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 32, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}
