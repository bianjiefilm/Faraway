import SwiftUI

struct ReminderOverlayView: View {
    let message: ReminderMessage
    let onDismiss: () -> Void

    @EnvironmentObject var sessionTracker: SessionTracker
    @State private var countdown: Int = 20
    @State private var showContent = false
    @State private var showRing = false
    @State private var showButton = false
    @State private var showGentleNudge = false
    @State private var timer: Timer?
    @State private var bubbleOffsets: [CGFloat] = [0, 0, 0, 0]
    @State private var backgroundImage: String = "插画日落系"

    private let bubbleXOffsets: [CGFloat] = [-120, 120, -60, 80]
    private let bubbleYBaseOffsets: [CGFloat] = [-200, 100, 250, -100]
    private let bubbleSizes: [CGFloat] = [100, 140, 70, 90]

    private let backgroundImages = [
        "插画日落系",
        "插画暖色系",
        "插画清凉系",
        "插画梦幻系",
        "插画清晨系"
    ]

    private let totalSeconds = 20

    var body: some View {
        ZStack {
            // Random illustration background
            Image(backgroundImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            // Overlay gradient for text readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Floating bubbles
            bubblesLayer

            // Grain texture overlay
            grainOverlay

            // Emergency Skip Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        timer?.invalidate()
                        onDismiss() // dismiss without recording
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white.opacity(0.2))
                            .padding(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)
                    .padding(.trailing, 24)
                }
                Spacer()
            }

            // Sunflower for special messages
            if message.isSpecial {
                VStack {
                    HStack {
                        Spacer()
                        Text("🌻")
                            .font(.system(size: 24))
                            .opacity(showContent ? 0.6 : 0)
                            .rotationEffect(.degrees(showContent ? 5 : -5))
                            .animation(
                                .easeInOut(duration: 3).repeatForever(autoreverses: true),
                                value: showContent
                            )
                            .padding(.trailing, 28)
                            .padding(.top, 24)
                    }
                    Spacer()
                }
            }

            // Main content
            VStack(spacing: 0) {
                Spacer()

                // Message text
                Text(message.text)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(12)
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 4)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: showContent)
                    .padding(.bottom, 44)

                // Ring countdown
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 3)
                        .frame(width: 150, height: 150)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: CGFloat(countdown) / CGFloat(totalSeconds))
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: countdown)

                    // Countdown number
                    VStack(spacing: 2) {
                        Text("\(countdown)")
                            .font(.system(size: 48, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: countdown)

                        Text("SEC")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(3)
                    }
                }
                .opacity(showRing ? 1 : 0)
                .offset(y: showRing ? 0 : 30)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: showRing)
                .padding(.bottom, 44)

                // Dismiss button
                Button(action: handleDismiss) {
                    Text("我休息好了 ✓")
                        .font(.system(size: 13, weight: countdown == 0 ? .semibold : .regular))
                        .foregroundColor(countdown == 0 ? .white : .white.opacity(0.3))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(countdown == 0 ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .stroke(countdown == 0 ? Color.white.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .cornerRadius(50)
                }
                .buttonStyle(.plain)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 30)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.9), value: showButton)
                .disabled(countdown > 0) // Lock button while counting down

                Spacer()
            }

            // Gentle nudge (shows when dismissed too early)
            VStack {
                Spacer()
                Text("再看一会儿远处嘛～ 对眼睛好 🌻")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.35))
                    .opacity(showGentleNudge ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: showGentleNudge)
                    .padding(.bottom, 100)
            }

            // Subtitle at bottom
            VStack {
                Spacer()
                Text(message.subtitle)
                    .font(.system(size: 11))
                    .italic()
                    .foregroundColor(.white.opacity(0.35))
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeIn.delay(1.2), value: showContent)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Randomly select a background image
            backgroundImage = backgroundImages.randomElement() ?? "插画日落系"

            startCountdown()
            withAnimation {
                showContent = true
                showRing = true
                showButton = true
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Bubbles

    private var bubblesLayer: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: bubbleSizes[i], height: bubbleSizes[i])
                    .offset(
                        x: bubbleXOffsets[i] + bubbleOffsets[i],
                        y: bubbleYBaseOffsets[i] + bubbleOffsets[i]
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                bubbleOffsets = [-40, 40, -30, 35]
            }
        }
    }

    // MARK: - Grain

    private var grainOverlay: some View {
        Canvas { context, size in
            // Simple noise-like pattern
            for _ in 0..<200 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color.white.opacity(Double.random(in: 0...0.02)))
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Timer

    private func startCountdown() {
        countdown = totalSeconds
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer?.invalidate()
                // Do not auto-dismiss anymore. Wait for user to click.
            }
        }
    }

    // MARK: - Dismiss

    private func handleDismiss() {
        // Since the button is disabled during countdown, this is only hit at countdown == 0
        timer?.invalidate()
        
        // Record the effective rest locally and in milestones
        sessionTracker.recordBreak()
        MilestoneManager.shared.recordEffectiveRest()
        
        onDismiss()
    }

}
