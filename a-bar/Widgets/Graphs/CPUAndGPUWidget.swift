import SwiftUI

/// CPU and GPU usage drawn together on one graph.
///
/// The two histories share a single plot, arranged like the network activity widget:
/// the CPU symbol and percent sit on the left, the GPU percent and icon sit on the
/// right, and both series run behind them. Each side uses that processor's graph color.
struct CPUAndGPUWidget: View {
  @EnvironmentObject var settings: SettingsManager
  @EnvironmentObject var systemInfo: SystemInfoService

  private var globalSettings: GlobalSettings {
    settings.settings.global
  }

  private var mergedSettings: CPUAndGPUWidgetSettings {
    settings.settings.widgets.cpuAndGpu
  }

  private var theme: ABarTheme {
    ThemeManager.currentTheme(for: settings.settings.theme)
  }

  var body: some View {
    let cpuColor = settings.settings.widgets.cpu.graphColor.color(from: theme)
    let gpuColor = settings.settings.widgets.gpu.graphColor.color(from: theme)

    BaseWidgetView(noPadding: true, onClick: openActivityMonitor) {
      ZStack {
        GeometryReader { geometry in
          ZStack {
            GraphView(
              values: systemInfo.cpuHistory.values,
              maxValue: 100.0,
              fillColor: cpuColor,
              lineColor: cpuColor,
              showLabels: false
            )
            GraphView(
              values: systemInfo.gpuHistory.values,
              maxValue: 100.0,
              fillColor: gpuColor,
              lineColor: gpuColor,
              showLabels: false
            )
          }
          .frame(width: geometry.size.width, height: geometry.size.height)
          .cornerRadius(globalSettings.barElementsCornerRadius)
          .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .padding(.horizontal, 0)
        .frame(width: 140)

        HStack {
          if mergedSettings.showIcon {
            Image(systemName: "cpu")
              .font(.system(size: 10))
              .foregroundColor(cpuColor)
              .padding(.leading, 6)
              .padding(.top, -6)
          }
          Text("\(Int(systemInfo.cpuUsage))%")
            .font(globalSettings.settingsFont(scaledBy: 0.8))
            .foregroundColor(cpuColor)
            .padding(.top, -6)
            .padding(.leading, mergedSettings.showIcon ? -4 : 6)
          Spacer()
        }

        HStack {
          Spacer()
          Text("\(Int(systemInfo.gpuUsage))%")
            .font(globalSettings.settingsFont(scaledBy: 0.8))
            .foregroundColor(gpuColor)
            .padding(.top, -6)
            .padding(.trailing, mergedSettings.showIcon ? -4 : 6)
          if mergedSettings.showIcon {
            WidgetTypeIcon(identifier: .gpu, pointSize: 10)
              .foregroundColor(gpuColor)
              .padding(.trailing, 6)
              .padding(.top, -6)
          }
        }
      }
    }
  }

  private func openActivityMonitor() {
    Task {
      _ = try? await ShellExecutor.run("open -a 'Activity Monitor'")
    }
  }
}
