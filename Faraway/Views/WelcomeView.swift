import SwiftUI

struct WelcomeView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private let pages: [(image: String, title: String, subtitle: String)] = [
        ("首次启动欢迎页a", "你好", "我是 Faraway，每 20 分钟提醒你休息一下"),
        ("功能介绍我会提醒你", "我会提醒你", "打开应用后，自动开始守护你的眼睛"),
        ("开始使用一起出发", "一起出发", "让每一次远眺都成为美好的时刻")
    ]

    var body: some View {
        ZStack {
            // Background
            Color(red: 10/255, green: 10/255, blue: 20/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Welcome illustration
                ForEach(0..<pages.count, id: \.self) { index in
                    if index == currentPage {
                        VStack(spacing: 24) {
                            Image(pages[index].image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .cornerRadius(16)

                            VStack(spacing: 8) {
                                Text(pages[index].title)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)

                                Text(pages[index].subtitle)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    }
                }
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage
                                ? Color(red: 251/255, green: 191/255, blue: 36/255)
                                : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 24)

                Spacer()

                // Button
                Button(action: handleButtonTap) {
                    Text(currentPage == pages.count - 1 ? "开始使用" : "下一步")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 10/255, green: 10/255, blue: 20/255))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 251/255, green: 191/255, blue: 36/255))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }

    private func handleButtonTap() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            onComplete()
        }
    }
}
