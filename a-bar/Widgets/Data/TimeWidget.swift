import SwiftUI

/// Time widget
struct TimeWidget: View {
  @EnvironmentObject var settings: SettingsManager

  @State private var currentTime = Date()
  @State private var refreshTimer: Timer?

  private var globalSettings: GlobalSettings {
    settings.settings.global
  }

  private var timeSettings: TimeWidgetSettings {
    settings.settings.widgets.time
  }

  private var theme: ABarTheme {
    ThemeManager.currentTheme(for: settings.settings.theme)
  }

  var body: some View {
    let bgColor = timeSettings.backgroundColor.color(from: theme)
    let fgColor =
      globalSettings.noColorInDataWidgets ? 
        theme.foreground : 
        bgColor.contrastingForeground(from: theme, opacity: globalSettings.barElementsBackgroundOpacity, barBackground: theme.background)

    BaseWidgetView(
      backgroundColor: globalSettings.noColorInDataWidgets
        ? theme.minor.opacity(0.95) : bgColor.opacity(0.95),
      noPadding: true
    ) {
      ZStack {
        if timeSettings.showDayProgress {
          DayProgressView(progress: currentTime.dayProgress, backgroundColor: fgColor)
        }
        HStack(spacing: 4) {
          if timeSettings.showIcon {
            TimeIconView(time: currentTime, iconColor: fgColor)
          }
          Text(formattedTime)
            .foregroundColor(fgColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
      }
      .clipped()
    }
    .onAppear {
      startTimer()
    }
    .onDisappear {
      refreshTimer?.invalidate()
      refreshTimer = nil
    }
  }

  private var formattedTime: String {
    WidgetLabels.time(
      currentTime, hour12: timeSettings.hour12, showSeconds: timeSettings.showSeconds)
  }

  private func startTimer() {
    refreshTimer?.invalidate()
    refreshTimer = Timer.scheduledTimer(withTimeInterval: timeSettings.refreshInterval, repeats: true) { _ in
      currentTime = Date()
    }
  }
}

struct TimeIconView: View {
  let time: Date
  let iconColor: Color

  @EnvironmentObject var settings: SettingsManager

  private var theme: ABarTheme {
    ThemeManager.currentTheme(for: settings.settings.theme)
  }

  var body: some View {
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: time)
    let minute = calendar.component(.minute, from: time)

    ZStack {
      Circle()
        .stroke(iconColor, lineWidth: 1)
        .frame(width: 16, height: 16)

      // Hour hand
      Rectangle()
        .fill(iconColor)
        .frame(width: 1, height: 5)
        .offset(y: -1.5)
        .rotationEffect(.degrees(Double(hour % 12) * 30 + Double(minute) * 0.5))

      // Minute hand
      Rectangle()
        .fill(iconColor)
        .frame(width: 0.5, height: 6)
        .offset(y: -2)
        .rotationEffect(.degrees(Double(minute) * 6))

      // Center dot
      Circle()
        .fill(iconColor)
        .frame(width: 2, height: 2)
    }
    .frame(width: 18, height: 18)
  }
}

struct DayProgressView: View {
  enum Axis {
    case horizontal
    case vertical
  }

  let progress: Double
  let backgroundColor: Color
  /// The time widget fills left to right. Sound and mic fill bottom to top.
  var axis: Axis = .horizontal

  @EnvironmentObject var settings: SettingsManager
  
  private var globalSettings: GlobalSettings {
    settings.settings.global
  }

  private var theme: ABarTheme {
    ThemeManager.currentTheme(for: settings.settings.theme)
  }

  var body: some View {
    GeometryReader { geometry in
      let fraction = min(max(progress, 0), 1)
      ZStack(alignment: axis == .horizontal ? .leading : .bottom) {
        Rectangle()
          .fill(theme.minor.opacity(0.05))
        Rectangle()
          .fill(backgroundColor.opacity(0.15))
          .frame(
            width: axis == .horizontal ? geometry.size.width * fraction : geometry.size.width,
            height: axis == .vertical ? geometry.size.height * fraction : geometry.size.height
          )
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .ignoresSafeArea()
    .allowsHitTesting(false)
    .clipShape(
      RoundedRectangle(cornerRadius: globalSettings.barElementsCornerRadius)
    )
  }
}

/// The sound and mic widgets with the level bar on: the day-progress fill stood on end, and
/// the percentage replaced by the icon.
struct IconLevelBar: View {
  let systemName: String
  let progress: Double
  let color: Color

  var body: some View {
    ZStack {
      DayProgressView(progress: progress, backgroundColor: color, axis: .vertical)
      Image(systemName: systemName)
        .font(.system(size: 11))
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }
    .clipped()
  }
}
