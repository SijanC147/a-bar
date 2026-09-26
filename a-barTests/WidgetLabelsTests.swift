import XCTest

/// Every string here has a width budget in a menu bar, and no failure mode louder than the wrong
/// text. The locale and time zone are parameters so these pin behaviour rather than the machine.
final class WidgetLabelsTests: XCTestCase {

  private let posix = Locale(identifier: "en_US_POSIX")
  private let utc = TimeZone(identifier: "UTC")!

  private func date(hour: Int, minute: Int, second: Int = 0) -> Date {
    var components = DateComponents()
    components.year = 2026
    components.month = 6
    components.day = 15
    components.hour = hour
    components.minute = minute
    components.second = second
    components.timeZone = utc
    return Calendar(identifier: .gregorian).date(from: components)!
  }

  // MARK: - The clock

  func testTwentyFourHourTime() {
    let time = date(hour: 14, minute: 5)

    XCTAssertEqual(
      WidgetLabels.time(time, hour12: false, showSeconds: false, locale: posix, timeZone: utc),
      "14:05")
  }

  func testTwelveHourTime() {
    let time = date(hour: 14, minute: 5)

    XCTAssertEqual(
      WidgetLabels.time(time, hour12: true, showSeconds: false, locale: posix, timeZone: utc),
      "2:05 PM")
  }

  func testSecondsAreShownOnRequest() {
    let time = date(hour: 14, minute: 5, second: 9)

    XCTAssertEqual(
      WidgetLabels.time(time, hour12: false, showSeconds: true, locale: posix, timeZone: utc),
      "14:05:09")
    XCTAssertEqual(
      WidgetLabels.time(time, hour12: true, showSeconds: true, locale: posix, timeZone: utc),
      "2:05:09 PM")
  }

  func testMidnightAndNoonReadCorrectlyInTwelveHourTime() {
    // The classic off-by-twelve: midnight is 12 AM, not 0 AM.
    XCTAssertEqual(
      WidgetLabels.time(date(hour: 0, minute: 0), hour12: true, showSeconds: false,
        locale: posix, timeZone: utc), "12:00 AM")
    XCTAssertEqual(
      WidgetLabels.time(date(hour: 12, minute: 0), hour12: true, showSeconds: false,
        locale: posix, timeZone: utc), "12:00 PM")
  }

  func testMinutesAreZeroPadded() {
    XCTAssertEqual(
      WidgetLabels.time(date(hour: 9, minute: 3), hour12: false, showSeconds: false,
        locale: posix, timeZone: utc), "09:03")
  }

  func testTheTimeZoneIsHonoured() {
    // The widget renders in the machine's zone; the parameter is what makes that testable.
    let time = date(hour: 14, minute: 0)
    let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    XCTAssertEqual(
      WidgetLabels.time(time, hour12: false, showSeconds: false, locale: posix, timeZone: tokyo),
      "23:00")
  }

  // MARK: - The date

  func testTheLongAndShortDateForms() {
    let day = date(hour: 12, minute: 0)

    XCTAssertEqual(
      WidgetLabels.date(day, localeIdentifier: "en_US_POSIX", shortFormat: false, timeZone: utc),
      "Monday, Jun 15")
    XCTAssertEqual(
      WidgetLabels.date(day, localeIdentifier: "en_US_POSIX", shortFormat: true, timeZone: utc),
      "Mon, Jun 15")
  }

  func testTheDateFollowsTheChosenLocale() {
    // The setting exists so a user can read the day name in their own language.
    let day = date(hour: 12, minute: 0)

    let french = WidgetLabels.date(
      day, localeIdentifier: "fr_FR", shortFormat: false, timeZone: utc)

    XCTAssertTrue(french.lowercased().contains("lundi"), "got \(french)")
  }

  // MARK: - Notification counts

  func testSmallCountsAreShownExactly() {
    XCTAssertEqual(WidgetLabels.notificationCount(0), "0")
    XCTAssertEqual(WidgetLabels.notificationCount(7), "7")
    XCTAssertEqual(WidgetLabels.notificationCount(99), "99", "the boundary is inclusive")
  }

  func testLargeCountsAreCappedSoTheBarDoesNotGrow() {
    XCTAssertEqual(WidgetLabels.notificationCount(100), "99+")
    XCTAssertEqual(WidgetLabels.notificationCount(4000), "99+")
  }

  // MARK: - Volume names

  func testTheBootVolumeIsAbbreviated() {
    XCTAssertEqual(WidgetLabels.storageVolumeName("Macintosh HD"), "Mac")
    XCTAssertEqual(WidgetLabels.storageVolumeName("macintosh hd"), "Mac", "case does not matter")
  }

  func testOtherVolumesKeepTheirName() {
    XCTAssertEqual(WidgetLabels.storageVolumeName("Backup"), "Backup")
    XCTAssertEqual(WidgetLabels.storageVolumeName(""), "")
  }

  // MARK: - Storage values stay five columns wide

  func testTheDefaultStorageReadingIsPercentageUsed() {
    XCTAssertEqual(StorageWidgetSettings().shownValue, .percentUsed)
  }

  func testPercentagesArePaddedToTheWidthOfOneHundredPercent() {
    XCTAssertEqual(WidgetLabels.storagePercent(0), "   0%")
    XCTAssertEqual(WidgetLabels.storagePercent(9), "   9%")
    XCTAssertEqual(WidgetLabels.storagePercent(10), "  10%")
    XCTAssertEqual(WidgetLabels.storagePercent(100), " 100%")
    XCTAssertEqual(WidgetLabels.storagePercent(250), " 100%", "a reading past full still fits")
    XCTAssertEqual(WidgetLabels.storagePercent(-4), "   0%")
  }

  func testRemainingSpaceUsesSmartPrecisionAtEachScale() {
    XCTAssertEqual(WidgetLabels.storageRemaining(0), "   0B")
    XCTAssertEqual(WidgetLabels.storageRemaining(512), " 512B")
    XCTAssertEqual(WidgetLabels.storageRemaining(1023), "1023B")
    XCTAssertEqual(WidgetLabels.storageRemaining(1024), "1.00K")
    XCTAssertEqual(WidgetLabels.storageRemaining(1536), "1.50K")
    XCTAssertEqual(WidgetLabels.storageRemaining(10 * 1024), "10.0K")
    XCTAssertEqual(WidgetLabels.storageRemaining(100 * 1024), " 100K")
    XCTAssertEqual(WidgetLabels.storageRemaining(1023 * 1024), "1023K")
    XCTAssertEqual(WidgetLabels.storageRemaining(1024 * 1024), "1.00M")
    XCTAssertEqual(WidgetLabels.storageRemaining(1024 * 1024 * 1024), "1.00G")
    XCTAssertEqual(WidgetLabels.storageRemaining(512 * 1024 * 1024 * 1024), " 512G")
    XCTAssertEqual(WidgetLabels.storageRemaining(1024 * 1024 * 1024 * 1024), "1.00T")
    let petabyte = 1024 * 1024 * 1024 * 1024 * 1024
    XCTAssertEqual(WidgetLabels.storageRemaining(petabyte), "1.00P")
    XCTAssertEqual(WidgetLabels.storageRemaining(petabyte * 1024), "1.00E")
  }

  func testRemainingSpaceRoundsIntoTheNextUnitInsteadOfPrinting1024() {
    // 1023.6K would print as 1024K, which is the next unit and a different width if left as-is.
    XCTAssertEqual(WidgetLabels.storageRemaining(Int((1023.6 * 1024).rounded())), "1.00M")
  }

  func testRemainingSpaceDropsADecimalWhenRoundingWouldAddAColumn() {
    XCTAssertEqual(WidgetLabels.storageRemaining(Int((99.96 * 1024).rounded())), " 100K")
    XCTAssertEqual(WidgetLabels.storageRemaining(Int((9.996 * 1024).rounded())), "10.0K")
  }

  func testRemainingSpaceStaysFiveColumnsAtEveryScale() {
    var bytes = 1
    var samples = [0, Int.max]
    while bytes > 0 && bytes < Int.max / 2 {
      samples.append(bytes)
      if bytes > 1 { samples.append(bytes - 1) }
      samples.append(bytes + 1)
      bytes *= 2
    }

    for sample in samples {
      let text = WidgetLabels.storageRemaining(sample)
      XCTAssertEqual(text.count, 5, "\(sample) formatted as \(text)")
      XCTAssertFalse(text.contains("\n"))
    }
  }

  func testANegativeRemainingReadingIsShownAsEmpty() {
    XCTAssertEqual(WidgetLabels.storageRemaining(-1), "   0B")
  }

  // MARK: - Keyboard layouts

  func testALayoutNameWithinBudgetIsShownWhole() {
    XCTAssertEqual(WidgetLabels.keyboardLayout("ABC"), "ABC")
    XCTAssertEqual(WidgetLabels.keyboardLayout("French"), "French")
    XCTAssertEqual(WidgetLabels.keyboardLayout("Vietnamese"), "Vietnamese", "ten still fits")
    XCTAssertEqual(WidgetLabels.keyboardLayout("British PC"), "British PC", "and so does this")
  }

  func testALongMultiWordNameIsCutToItsFirstWord() {
    XCTAssertEqual(WidgetLabels.keyboardLayout("Canadian French"), "Canadian")
    XCTAssertEqual(WidgetLabels.keyboardLayout("Russian Phonetic"), "Russian")
  }

  func testALongSingleWordNameIsTruncated() {
    // regression: this branch was guarded by `split(separator: " ").first`, which is never nil
    // for a non-empty string, so it could not be reached. A long single-word layout came through
    // at full width and pushed the rest of the bar along.
    XCTAssertEqual(WidgetLabels.keyboardLayout("Netherlands"), "Netherla…")
  }

  func testALongFirstWordIsTruncatedRatherThanShownWhole() {
    // Taking the first word only helps when the first word is itself short enough.
    XCTAssertEqual(WidgetLabels.keyboardLayout("Extraordinarily Long"), "Extraord…")
  }

  func testNoLayoutNameEverExceedsItsBudget() {
    // The property the whole function exists for.
    let names = [
      "ABC", "British PC", "Vietnamese", "Netherlands", "Extraordinarily Long",
      "Canadian French", "Pinyin - Simplified", "",
    ]

    for name in names {
      XCTAssertLessThanOrEqual(
        WidgetLabels.keyboardLayout(name).count, 10, "\(name) came through too wide")
    }
  }
}
