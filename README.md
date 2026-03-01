<p align="center">
  <img src="assets/icon-256.png" width="128" height="128" alt="Faraway">
</p>

<h1 align="center">Faraway</h1>

<p align="center">
  A macOS menu bar app that reminds you to look faraway.<br>
  一款提醒你看看远处的 macOS 菜单栏应用。
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS_13+-000?style=flat-square" alt="macOS 13+">
  <img src="https://img.shields.io/badge/swift-5.9+-F05138?style=flat-square" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT">
</p>

---

## English

### What is Faraway?

Faraway is a menu bar app for macOS based on the [20-20-20 rule](https://www.aoa.org/healthy-eyes/eye-and-vision-conditions/computer-vision-syndrome): every 20 minutes, look at something 20 feet away for 20 seconds. It was originally made for someone who spends long hours editing videos and forgets to rest her eyes.

### Features

- 🌻 **Smart Reminders** — Full-screen reminders with a 20-second countdown, different colors and messages each time
- 🎯 **App Monitoring** — Detects when you're using editing apps (video, image, code editors) and activates automatically
- ⏱️ **Customizable Timer** — Set your preferred break interval
- 🎨 **Beautiful Design** — Sunflower-themed UI with illustrations
- 📊 **Eye Care Tracking** — Counts only completed breaks (full 20 seconds + tap "I'm rested")
- 🏆 **Milestones** — Special messages at certain counts, rarer over time
- 🌙 **Late Night Mode** — Different reminder tone after midnight
- 📅 **Special Days** — Certain dates have unique messages
- 🚀 **Launch at Login** — Option to start automatically on Mac boot
- 📊 **Daily Summary** — Track your daily eye care progress

### Installation

1. Download the latest `.dmg` from [Releases](https://github.com/user/faraway/releases)
2. Open the DMG file
3. Drag `Faraway.app` to your Applications folder
4. Launch Faraway from Applications

### Build from Source

```bash
git clone https://github.com/user/faraway.git
cd faraway
open Faraway.xcodeproj
# Build and run (⌘R)
```

Requires Xcode 15+ and macOS 13.0+.

### First Launch

On first launch, you'll be asked if you want to enable "Launch at Login" for automatic starting.

### Usage

1. **Menu Bar Icon** — Look for the sunflower eye icon 🌻 in your menu bar
2. **Click to Open** — Click the icon to see timer status and settings
3. **Start Monitoring** — Timer starts automatically when you open an editing app
4. **Take Breaks** — When the timer ends, a full-screen reminder appears with a 20-second countdown
5. **Confirm Rest** — After the countdown, tap "I'm rested" to log a completed break
6. **Settings** — Customize your experience in the settings section

### How Tracking Works

Only completed breaks count toward milestones and streaks. A break is completed when:

1. The full 20-second countdown finishes
2. You tap the "I'm rested" button

Closing the reminder early does not count. No inflated numbers.

**Streaks** track consecutive days of use — miss a day and it resets.

### Settings

- **Monitoring Mode:**
  - Global Mode — Monitor all apps
  - Select Apps — Choose specific apps to monitor
- **Launch at Login** — Enable/disable automatic startup

### Privacy

Faraway makes no network requests. No analytics, no telemetry. All data stays on your Mac.

### System Requirements

- macOS 13.0 (Ventura) or later

---

## 中文

### 什么是 Faraway？

Faraway 是一款 macOS 菜单栏应用，基于 [20-20-20 护眼法则](https://www.aoa.org/healthy-eyes/eye-and-vision-conditions/computer-vision-syndrome)：每 20 分钟，看一眼 20 英尺（约 6 米）远的地方，持续 20 秒。最初是为一个长时间剪辑视频、总忘记休息眼睛的人做的。

### 功能特点

- 🌻 **智能提醒** — 全屏提醒搭配 20 秒倒计时，每次颜色和文案都不同
- 🎯 **应用监测** — 检测到剪辑类软件运行时自动激活（视频、图片、代码编辑器）
- ⏱️ **自定义计时** — 设置你偏好的休息间隔
- 🎨 **精美设计** — 向日葵主题 UI，搭配插画
- 📊 **护眼记录** — 只统计完整休息（20 秒倒计时结束 + 点击"我休息好了"）
- 🏆 **里程碑** — 特定次数时出现特别的文案，越往后越稀有
- 🌙 **深夜模式** — 午夜之后提醒语气会不一样
- 📅 **特别日子** — 某些日期会有不一样的提醒
- 🚀 **开机启动** — 支持开机自动启动
- 📊 **每日总结** — 追踪每天的护眼数据

### 安装方法

1. 从 [Releases](https://github.com/user/faraway/releases) 下载最新的 `.dmg` 文件
2. 打开 DMG 文件
3. 将 `Faraway.app` 拖入应用程序文件夹
4. 从应用程序中启动 Faraway

### 从源码构建

```bash
git clone https://github.com/user/faraway.git
cd faraway
open Faraway.xcodeproj
# Build and run (⌘R)
```

需要 Xcode 15+ 和 macOS 13.0+。

### 首次启动

首次启动时，会询问是否开启"开机启动"选项。

### 使用方法

1. **菜单栏图标** — 在菜单栏找到向日葵眼睛图标 🌻
2. **点击打开** — 点击图标查看计时状态和设置
3. **开始监测** — 打开剪辑软件时计时器自动开始
4. **休息提醒** — 计时结束后弹出全屏提醒，20 秒倒计时
5. **确认休息** — 倒计时结束后点击"我休息好了"完成一次有效护眼
6. **设置** — 在设置区域自定义体验

### 记录机制

只有完成的休息才会被统计。完成条件：

1. 20 秒倒计时走完
2. 点击"我休息好了"按钮

提前关闭不计入。不注水。

**连续天数**追踪每日使用情况——断一天就重新计。

### 设置说明

- **监测模式：**
  - 全局模式 — 监测所有应用
  - 手动选择 — 选择特定应用进行监测
- **开机启动** — 开启/关闭开机自动启动

### 隐私

Faraway 不发送任何网络请求。没有数据分析，没有遥测。所有数据只存在你的 Mac 上。

### 系统要求

- macOS 13.0 (Ventura) 或更高版本

---

## License

MIT — see [LICENSE](LICENSE) for details.

## Contributing

Issues and PRs are welcome.

---

<p align="center">
  <sub>for someone far away 🌻</sub>
</p>
