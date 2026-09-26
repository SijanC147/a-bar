import Foundation

/// The short strings the bar puts on screen.
///
/// Every formatter here takes the values it reads rather than the ambient ones, so a test can
/// pin a clock without waiting for a second to pass and without depending on the machine's
/// locale. The production defaults are the ambient reads the views used to make inline.
enum WidgetLabels {

  // MARK: - Clock

  /// The clock face.
  ///
  /// The locale is a parameter rather than fixed to POSIX because the am/pm marker is localized
  /// and forcing it would change what non-English users see. Tests pass an explicit one.
  static func time(
    _ date: Date, hour12: Bool, showSeconds: Bool,
    locale: Locale = .current, timeZone: TimeZone = .current
  ) -> String {
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.timeZone = timeZone

    if hour12 {
      formatter.dateFormat = showSeconds ? "h:mm:ss a" : "h:mm a"
    } else {
      formatter.dateFormat = showSeconds ? "HH:mm:ss" : "HH:mm"
    }

    return formatter.string(from: date)
  }

  static func date(
    _ date: Date, localeIdentifier: String, shortFormat: Bool, timeZone: TimeZone = .current
  ) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: localeIdentifier)
    formatter.timeZone = timeZone
    formatter.dateFormat = shortFormat ? "EE, MMM d" : "EEEE, MMM d"

    return formatter.string(from: date)
  }

  // MARK: - Counts and names

  /// A notification count wide enough to fit in the bar.
  static func notificationCount(_ count: Int) -> String {
    count > 99 ? "99+" : "\(count)"
  }

  /// The boot volume is called "Macintosh HD" by default, which is too wide to be worth showing.
  static func storageVolumeName(_ name: String) -> String {
    name.lowercased().contains("macintosh") ? "Mac" : name
  }

  /// A storage percentage. Always five columns (`" 100%"`, `"   9%"`), so the bar does not
  /// resize as the number changes.
  static func storagePercent(_ percent: Int) -> String {
    String(format: "%4d%%", min(100, max(0, percent)))
  }

  /// Free space for the storage widget. Always five columns: smart precision and one unit.
  ///
  /// The unit is B below 1024 bytes, then K, M, G, T, P, or E, stepping at powers of 1024.
  /// Under 10 of a unit the number has two decimals (`1.50G`), under 100 it has one (`12.3G`),
  /// and from there it is whole (` 512G`). The decimal point is always `.`, so a locale that
  /// uses a comma cannot make the label a different width.
  static func storageRemaining(_ bytes: Int) -> String {
    var value = Double(max(0, bytes))
    var index = 0
    while index < storageUnits.count - 1 && storagePromotes(value, fromBytes: index == 0) {
      value /= 1024
      index += 1
    }
    if index == 0 {
      return String(format: "%4dB", Int(value.rounded()))
    }
    return storageScaled(value) + storageUnits[index]
  }

  private static let storageUnits = ["B", "K", "M", "G", "T", "P", "E"]
  private static let storageLocale = Locale(identifier: "en_US_POSIX")

  /// True when rounding this value in its display precision would print 1024 and belong in the
  /// next unit. Bytes are already whole, so they step at 1024 exactly.
  private static func storagePromotes(_ value: Double, fromBytes: Bool) -> Bool {
    if fromBytes { return value >= 1024 }
    if value >= 1024 { return true }
    return value >= 100 && value.rounded() >= 1024
  }

  /// Four characters of magnitude. Precision drops as the number grows so the width stays put,
  /// including where one decimal would round to `100.0`.
  private static func storageScaled(_ value: Double) -> String {
    let hundredths = (value * 100).rounded() / 100
    if hundredths >= 99.95 {
      return String(format: "%4.0f", locale: storageLocale, hundredths.rounded())
    }
    if hundredths >= 9.995 {
      return String(format: "%4.1f", locale: storageLocale, hundredths)
    }
    return String(format: "%4.2f", locale: storageLocale, hundredths)
  }

  /// A keyboard layout name short enough for the bar.
  ///
  /// The first word is usually the language ("British PC" -> "British"), but a single long word
  /// has no space to cut at, so it is truncated instead. That fallback used to be unreachable:
  /// it was guarded by `split(separator: " ").first`, which is never nil for a non-empty string,
  /// so "Vietnamese" came through at full width while "British PC" was shortened.
  static func keyboardLayout(_ layout: String, maxLength: Int = 10) -> String {
    guard layout.count > maxLength else { return layout }

    if let firstWord = layout.split(separator: " ").first, firstWord.count <= maxLength {
      return String(firstWord)
    }

    return layout.truncated(to: maxLength - 2)
  }
}
