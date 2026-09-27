import Foundation

/// A kind of solar event the solar widget can show. The user enables each one.
enum SolarEventKind: String, Codable, CaseIterable, Identifiable {
  case astronomicalTwilight
  case nauticalTwilight
  case civilTwilight
  case blueHour
  case goldenHour
  case sunrise
  case solarNoon
  case sunset

  var id: String { rawValue }

  var title: String {
    switch self {
    case .astronomicalTwilight: return "Astronomical twilight"
    case .nauticalTwilight: return "Nautical twilight"
    case .civilTwilight: return "Civil twilight"
    case .blueHour: return "Blue hour"
    case .goldenHour: return "Golden hour"
    case .sunrise: return "Sunrise"
    case .solarNoon: return "Solar noon"
    case .sunset: return "Sunset"
    }
  }

  /// Template image in the asset catalog.
  var iconAssetName: String {
    switch self {
    case .astronomicalTwilight: return "SolarAstronomical"
    case .nauticalTwilight: return "SolarNautical"
    case .civilTwilight: return "SolarCivil"
    case .blueHour: return "SolarBlueHour"
    case .goldenHour: return "SolarGoldenHour"
    case .sunrise: return "SolarSunrise"
    case .solarNoon: return "SolarNoon"
    case .sunset: return "SolarSunset"
    }
  }

  /// Theme colour the icon is tinted with.
  var colorRole: ThemeColorRole {
    switch self {
    case .astronomicalTwilight: return .magenta
    case .nauticalTwilight, .blueHour: return .blue
    case .civilTwilight: return .cyan
    case .goldenHour: return .orange
    case .sunrise, .solarNoon, .sunset: return .yellow
    }
  }
}

/// One moment in the day: a solar event beginning.
struct SolarMoment: Equatable {
  let kind: SolarEventKind
  /// "Sunrise", "Evening golden hour", "Last light" and so on.
  let label: String
  let date: Date
}

/// Sun altitude events for one day and place, from the NOAA solar calculator equations.
///
/// Accurate to about a minute between the polar circles. An event the sun does not reach that
/// day (no sunset in polar summer, no astronomical twilight on a white night) is left out.
enum SolarTimes {

  /// Sun altitudes, in degrees, that start each event.
  enum Altitude {
    static let horizon = -0.833  // upper limb on the horizon, with refraction
    static let civil = -6.0
    static let nautical = -12.0
    static let astronomical = -18.0
    static let blueHourEnd = -4.0
    static let goldenHourHigh = 6.0
  }

  /// Every event that starts on the given local day, sorted by time.
  static func moments(
    on day: Date, latitude: Double, longitude: Double, timeZone: TimeZone
  ) -> [SolarMoment] {
    guard let midnight = utcMidnight(of: day, in: timeZone) else { return [] }

    func rising(_ altitude: Double) -> Date? {
      eventTime(midnight: midnight, latitude: latitude, longitude: longitude, altitude: altitude, rising: true)
    }
    func setting(_ altitude: Double) -> Date? {
      eventTime(midnight: midnight, latitude: latitude, longitude: longitude, altitude: altitude, rising: false)
    }

    var result: [SolarMoment] = []
    func add(_ kind: SolarEventKind, _ label: String, _ date: Date?) {
      if let date { result.append(SolarMoment(kind: kind, label: label, date: date)) }
    }

    add(.astronomicalTwilight, "Astronomical dawn", rising(Altitude.astronomical))
    add(.nauticalTwilight, "Nautical dawn", rising(Altitude.nautical))
    add(.civilTwilight, "First light", rising(Altitude.civil))
    add(.blueHour, "Morning blue hour", rising(Altitude.civil))
    add(.goldenHour, "Morning golden hour", rising(Altitude.blueHourEnd))
    add(.sunrise, "Sunrise", rising(Altitude.horizon))
    add(.solarNoon, "Solar noon", solarNoon(midnight: midnight, longitude: longitude))
    add(.goldenHour, "Evening golden hour", setting(Altitude.goldenHourHigh))
    add(.sunset, "Sunset", setting(Altitude.horizon))
    add(.blueHour, "Evening blue hour", setting(Altitude.blueHourEnd))
    add(.civilTwilight, "Last light", setting(Altitude.civil))
    add(.nauticalTwilight, "Nautical dusk", setting(Altitude.nautical))
    add(.astronomicalTwilight, "Astronomical dusk", setting(Altitude.astronomical))

    return result.sorted { $0.date < $1.date }
  }

  /// The first enabled moment after `now`, looking at today and then tomorrow.
  static func nextMoment(
    after now: Date, kinds: Set<SolarEventKind>, latitude: Double, longitude: Double,
    timeZone: TimeZone
  ) -> SolarMoment? {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    for offset in 0...1 {
      guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
      let upcoming = moments(on: day, latitude: latitude, longitude: longitude, timeZone: timeZone)
        .filter { kinds.contains($0.kind) && $0.date > now }
      if let first = upcoming.first { return first }
    }
    return nil
  }

  /// "2h 05m" or "14m" until `date`.
  static func countdown(from now: Date, to date: Date) -> String {
    let minutes = max(0, Int((date.timeIntervalSince(now) / 60).rounded(.up)))
    let hours = minutes / 60
    let rest = minutes % 60
    return hours > 0 ? String(format: "%dh %02dm", hours, rest) : "\(rest)m"
  }

  // MARK: - NOAA equations

  private static func utcMidnight(of day: Date, in timeZone: TimeZone) -> Date? {
    var local = Calendar(identifier: .gregorian)
    local.timeZone = timeZone
    let parts = local.dateComponents([.year, .month, .day], from: day)
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(identifier: "UTC")!
    return utc.date(from: parts)
  }

  private struct SunParameters {
    let declination: Double  // radians
    let equationOfTime: Double  // minutes
  }

  private static func sunParameters(at date: Date) -> SunParameters {
    let julianDay = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
    let t = (julianDay - 2_451_545) / 36_525

    let meanLongitude = (280.46646 + t * (36_000.76983 + t * 0.0003032))
      .truncatingRemainder(dividingBy: 360)
    let meanAnomaly = 357.52911 + t * (35_999.05029 - 0.0001537 * t)
    let eccentricity = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
    let m = radians(meanAnomaly)
    let center = sin(m) * (1.914602 - t * (0.004817 + 0.000014 * t))
      + sin(2 * m) * (0.019993 - 0.000101 * t) + sin(3 * m) * 0.000289
    let omega = radians(125.04 - 1934.136 * t)
    let apparentLongitude = meanLongitude + center - 0.00569 - 0.00478 * sin(omega)
    let meanObliquity = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
    let obliquity = radians(meanObliquity + 0.00256 * cos(omega))

    let declination = asin(sin(obliquity) * sin(radians(apparentLongitude)))
    let y = pow(tan(obliquity / 2), 2)
    let l0 = radians(meanLongitude)
    let equationOfTime = 4 * degrees(
      y * sin(2 * l0) - 2 * eccentricity * sin(m)
        + 4 * eccentricity * y * sin(m) * cos(2 * l0)
        - 0.5 * y * y * sin(4 * l0) - 1.25 * eccentricity * eccentricity * sin(2 * m))
    return SunParameters(declination: declination, equationOfTime: equationOfTime)
  }

  private static func solarNoon(midnight: Date, longitude: Double) -> Date {
    var minutes = 720 - 4 * longitude
    for _ in 0..<2 {
      let parameters = sunParameters(at: midnight.addingTimeInterval(minutes * 60))
      minutes = 720 - 4 * longitude - parameters.equationOfTime
    }
    return midnight.addingTimeInterval(minutes * 60)
  }

  /// When the sun crosses `altitude`, rising or setting, or nil if it does not that day.
  private static func eventTime(
    midnight: Date, latitude: Double, longitude: Double, altitude: Double, rising: Bool
  ) -> Date? {
    let noon = solarNoon(midnight: midnight, longitude: longitude)
    var estimate = noon
    var result: Date?
    // Recompute the sun's position at the estimate: once from noon, then refine.
    for _ in 0..<3 {
      let parameters = sunParameters(at: estimate)
      let phi = radians(latitude)
      let delta = parameters.declination
      let cosHourAngle = (sin(radians(altitude)) - sin(phi) * sin(delta)) / (cos(phi) * cos(delta))
      guard (-1...1).contains(cosHourAngle) else { return nil }
      let hourAngle = degrees(acos(cosHourAngle))
      let minutesFromMidnight = 720 - 4 * longitude - parameters.equationOfTime
        + (rising ? -4 * hourAngle : 4 * hourAngle)
      let candidate = midnight.addingTimeInterval(minutesFromMidnight * 60)
      result = candidate
      estimate = candidate
    }
    return result
  }

  private static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
  private static func degrees(_ radians: Double) -> Double { radians * 180 / .pi }
}
