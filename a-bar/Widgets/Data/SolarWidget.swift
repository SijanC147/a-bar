import SwiftUI

/// Next solar event (sunrise, golden hour, twilight...) as a clock time or a countdown.
/// Clicking opens a popover with every enabled event of the day.
struct SolarWidget: View {
  let position: BarPosition

  @EnvironmentObject var settings: SettingsManager

  @StateObject private var popoverManager = WidgetPopoverManager(minWidth: 240, maxHeight: 420)
  @State private var coordinate: SolarCoordinate?

  /// Same point size as a macOS menu-bar status icon.
  private let iconSize: CGFloat = 16

  private var solarSettings: SolarWidgetSettings { settings.settings.widgets.solar }
  private var theme: ABarTheme { ThemeManager.currentTheme(for: settings.settings.theme) }
  private var locationQuery: String { settings.settings.widgets.weather.customLocation }

  var body: some View {
    TimelineView(.periodic(from: .now, by: 30)) { context in
      BaseWidgetView(onClick: { popoverManager.toggle() }, onRightClick: resolveLocation) {
        label(now: context.date)
      }
    }
    .background(
      WidgetPopoverAnchor(
        onMake: { view in
          popoverManager.attach(anchorView: view, position: position)
          popoverManager.setContent {
            SolarPopoverContent(coordinate: coordinate)
              .environmentObject(settings)
          }
        }
      )
    )
    .onAppear { if coordinate == nil { resolveLocation() } }
    .onChange(of: locationQuery) { _ in resolveLocation() }
    .onChange(of: coordinate) { newValue in
      popoverManager.setContent {
        SolarPopoverContent(coordinate: newValue)
          .environmentObject(settings)
      }
    }
  }

  @ViewBuilder
  private func label(now: Date) -> some View {
    if let coordinate,
      let next = SolarTimes.nextMoment(
        after: now, kinds: Set(solarSettings.enabledEvents), latitude: coordinate.latitude,
        longitude: coordinate.longitude, timeZone: .current)
    {
      HStack(spacing: 4) {
        if solarSettings.showIcon {
          SolarEventIcon(kind: next.kind, size: iconSize)
            .foregroundColor(next.kind.colorRole.color(in: theme))
        }
        Text(
          solarSettings.displayMode == .timeLeft
            ? SolarTimes.countdown(from: now, to: next.date)
            : Self.clock.string(from: next.date)
        )
        .foregroundColor(theme.foreground)
      }
      .help(next.label)
    } else {
      HStack(spacing: 4) {
        if solarSettings.showIcon {
          SolarEventIcon(kind: .sunrise, size: iconSize)
            .foregroundColor(theme.minor)
        }
        Text("--:--").foregroundColor(theme.minor)
      }
    }
  }

  static let clock: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter
  }()

  private func resolveLocation() {
    let query = locationQuery
    Task {
      if let found = await SolarCoordinate.resolve(query: query) {
        await MainActor.run { coordinate = found }
      }
    }
  }
}

struct SolarEventIcon: View {
  let kind: SolarEventKind
  let size: CGFloat

  var body: some View {
    Image(kind.iconAssetName)
      .renderingMode(.template)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: size, height: size)
  }
}

/// Every enabled event today, with its time and how long until it.
struct SolarPopoverContent: View {
  let coordinate: SolarCoordinate?

  @EnvironmentObject var settings: SettingsManager

  private var theme: ABarTheme { ThemeManager.currentTheme(for: settings.settings.theme) }
  private var enabled: Set<SolarEventKind> { Set(settings.settings.widgets.solar.enabledEvents) }

  var body: some View {
    TimelineView(.periodic(from: .now, by: 30)) { context in
      VStack(alignment: .leading, spacing: 8) {
        Text("Today").font(.headline)
        if let coordinate {
          let moments = SolarTimes.moments(
            on: context.date, latitude: coordinate.latitude, longitude: coordinate.longitude,
            timeZone: .current
          ).filter { enabled.contains($0.kind) }
          if moments.isEmpty {
            Text("No enabled events happen today.").foregroundColor(.secondary)
          }
          ForEach(moments, id: \.label) { moment in
            let past = moment.date <= context.date
            HStack(spacing: 8) {
              SolarEventIcon(kind: moment.kind, size: 16)
                .foregroundColor(moment.kind.colorRole.color(in: theme))
              Text(moment.label)
              Spacer(minLength: 12)
              Text(SolarWidget.clock.string(from: moment.date)).monospacedDigit()
              Text(past ? "" : SolarTimes.countdown(from: context.date, to: moment.date))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .frame(width: 64, alignment: .trailing)
            }
            .opacity(past ? 0.45 : 1)
          }
        } else {
          Text("Finding your location...").foregroundColor(.secondary)
        }
      }
      .padding(12)
    }
  }
}

/// Where the solar times are computed for. Taken from the Weather widget's custom location,
/// or from IP geolocation when that is empty.
struct SolarCoordinate: Equatable {
  let latitude: Double
  let longitude: Double

  static func resolve(query: String) async -> SolarCoordinate? {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return await fromIPAddress()
    }
    return await geocode(trimmed)
  }

  private static func fromIPAddress() async -> SolarCoordinate? {
    guard let url = URL(string: "http://ip-api.com/json/?fields=lat,lon"),
      let response = try? await URLSession.shared.data(from: url),
      let json = try? JSONSerialization.jsonObject(with: response.0) as? [String: Any],
      let lat = json["lat"] as? Double, let lon = json["lon"] as? Double
    else { return nil }
    return SolarCoordinate(latitude: lat, longitude: lon)
  }

  private static func geocode(_ name: String) async -> SolarCoordinate? {
    guard
      let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
      let url = URL(
        string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=1"),
      let response = try? await URLSession.shared.data(from: url),
      let json = try? JSONSerialization.jsonObject(with: response.0) as? [String: Any],
      let first = (json["results"] as? [[String: Any]])?.first,
      let lat = first["latitude"] as? Double, let lon = first["longitude"] as? Double
    else { return await fromIPAddress() }
    return SolarCoordinate(latitude: lat, longitude: lon)
  }
}
