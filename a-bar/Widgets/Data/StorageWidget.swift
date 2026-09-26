import SwiftUI

/// Storage usage widget with vertical bars for each volume
enum StorageWidgetConstants {
    static let barWidth: CGFloat = 16
    static let barHeight: CGFloat = 22
}

struct StorageWidget: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var storageInfo: SystemInfoService

    private var theme: ABarTheme {
        ThemeManager.currentTheme(for: settings.settings.theme)
    }

    private var storageSettings: StorageWidgetSettings {
        settings.settings.widgets.storage
    }

    private var visibleVolumes: [StorageVolume] {
        StorageVolumeSelection.visibleVolumes(
            storageInfo.volumes, selected: storageSettings.selectedVolumes)
    }

    var body: some View {
        BaseWidgetView(
            noPadding: true,
            onClick: openDiskUtility
        ) {
            HStack(spacing: 6) {
                ForEach(visibleVolumes) { volume in
                    HStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3)
                                .frame(width: StorageWidgetConstants.barWidth, height: StorageWidgetConstants.barHeight)
                                .foregroundColor(theme.mainAlt.opacity(0.18))
                            RoundedRectangle(cornerRadius: 3)
                                .frame(width: StorageWidgetConstants.barWidth, height: StorageWidgetConstants.barHeight * CGFloat(volume.fullness))
                                .foregroundColor(barColor(for: volume))
                        }
                        VStack(alignment: .leading) {
                            Text(shownValue(for: volume))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(theme.foreground)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                            Text(shortName(for: volume.name))
                                .font(.system(size: 8))
                                .foregroundColor(theme.foreground.opacity(0.7))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: 50)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
        }
    }

    private func shownValue(for volume: StorageVolume) -> String {
        switch storageSettings.shownValue {
        case .percentUsed:
            return WidgetLabels.storagePercent(volume.fullnessPercent)
        case .percentRemaining:
            return WidgetLabels.storagePercent(volume.remainingPercent)
        case .spaceRemaining:
            return WidgetLabels.storageRemaining(volume.remainingBytes)
        }
    }

    private func barColor(for volume: StorageVolume) -> Color {
        WidgetPalette.storageBar(fullness: volume.fullness).color(in: theme)
    }

    private func shortName(for name: String) -> String {
        WidgetLabels.storageVolumeName(name)
    }

    private func openDiskUtility() {
        Task {
            _ = try? await ShellExecutor.run("open -a 'Disk Utility'")
        }
    }
}
