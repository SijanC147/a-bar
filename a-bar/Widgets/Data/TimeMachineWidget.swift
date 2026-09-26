import SwiftUI

/// Menu-bar Time Machine mark.
///
/// Idle and in-progress both use the history glyph. A backup in progress rotates it.
/// A failed last backup, with nothing running, uses the alert glyph.
struct TimeMachineWidget: View {
  @EnvironmentObject var settings: SettingsManager
  @EnvironmentObject var systemInfo: SystemInfoService

  @State private var spin = false

  /// Same point size as a macOS menu-bar status icon.
  private let menuBarIconSize: CGFloat = 16

  private var timeMachineSettings: TimeMachineWidgetSettings {
    settings.settings.widgets.timeMachine
  }

  private var theme: ABarTheme {
    ThemeManager.currentTheme(for: settings.settings.theme)
  }

  var body: some View {
    let state = systemInfo.timeMachine
    BaseWidgetView(onClick: openTimeMachineSettings) {
      if timeMachineSettings.showIcon {
        icon(for: state)
          .foregroundColor(theme.foreground)
      } else {
        Text("TM")
          .foregroundColor(theme.foreground)
      }
    }
  }

  private func icon(for state: TimeMachineBackupState) -> some View {
    let asset = state == .failed ? "TimeMachineFailed" : "TimeMachineIcon"
    return Image(asset)
      .renderingMode(.template)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: menuBarIconSize, height: menuBarIconSize)
      .rotationEffect(.degrees(state == .running && spin ? 360 : 0))
      .animation(
        state == .running
          ? .linear(duration: 1.5).repeatForever(autoreverses: false)
          : .linear(duration: 0.2),
        value: spin
      )
      .onAppear {
        spin = state == .running
      }
      .onChange(of: state) { newState in
        spin = false
        if newState == .running {
          DispatchQueue.main.async { spin = true }
        }
      }
  }

  private func openTimeMachineSettings() {
    Task {
      _ = try? await ShellExecutor.run("open /System/Library/PreferencePanes/TimeMachine.prefPane/")
    }
  }
}
