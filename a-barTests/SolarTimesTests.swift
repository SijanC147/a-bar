import XCTest

final class SolarTimesTests: XCTestCase {

  private let utc = TimeZone(identifier: "UTC")!
  private let london = (latitude: 51.5074, longitude: -0.1278)
  private let tromso = (latitude: 69.6492, longitude: 18.9553)

  private func date(_ text: String) -> Date {
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: text)!
  }

  private func moment(_ label: String, in moments: [SolarMoment]) -> SolarMoment? {
    moments.first { $0.label == label }
  }

  /// London, 21 June 2024: sunrise 04:43 BST, solar noon 13:02 BST, sunset 21:21 BST
  /// (timeanddate.com). One minute of rounding either way, plus a minute for the model.
  func testLondonMidsummerMatchesPublishedTimes() throws {
    let moments = SolarTimes.moments(
      on: date("2024-06-21T12:00:00Z"), latitude: london.latitude, longitude: london.longitude,
      timeZone: utc)

    let sunrise = try XCTUnwrap(moment("Sunrise", in: moments))
    let noon = try XCTUnwrap(moment("Solar noon", in: moments))
    let sunset = try XCTUnwrap(moment("Sunset", in: moments))

    XCTAssertEqual(sunrise.date.timeIntervalSince(date("2024-06-21T03:43:00Z")), 0, accuracy: 120)
    XCTAssertEqual(noon.date.timeIntervalSince(date("2024-06-21T12:02:00Z")), 0, accuracy: 120)
    XCTAssertEqual(sunset.date.timeIntervalSince(date("2024-06-21T20:21:00Z")), 0, accuracy: 120)
  }

  /// No astronomical night in London at midsummer: the sun never gets 18 degrees down.
  func testLondonMidsummerHasNoAstronomicalTwilight() {
    let moments = SolarTimes.moments(
      on: date("2024-06-21T12:00:00Z"), latitude: london.latitude, longitude: london.longitude,
      timeZone: utc)
    XCTAssertFalse(moments.contains { $0.kind == .astronomicalTwilight })
  }

  func testMomentsAreSortedAndFollowTheSkyInOrder() {
    let moments = SolarTimes.moments(
      on: date("2024-03-20T12:00:00Z"), latitude: london.latitude, longitude: london.longitude,
      timeZone: utc)
    XCTAssertEqual(moments.map(\.date), moments.map(\.date).sorted())
    XCTAssertEqual(moments.count, 13)

    // The sky's order through an equinox day. First light and the morning blue hour share
    // an altitude, so they may be equal.
    let skyOrder = [
      "Astronomical dawn", "Nautical dawn", "First light", "Morning blue hour",
      "Morning golden hour", "Sunrise", "Solar noon", "Evening golden hour", "Sunset",
      "Evening blue hour", "Last light", "Nautical dusk", "Astronomical dusk",
    ]
    let dates = skyOrder.compactMap { moment($0, in: moments)?.date }
    XCTAssertEqual(dates.count, skyOrder.count)
    for (earlier, later) in zip(dates, dates.dropFirst()) {
      XCTAssertLessThanOrEqual(earlier, later)
    }
  }

  func testPolarDayHasNoSunriseOrSunset() {
    let moments = SolarTimes.moments(
      on: date("2024-06-21T12:00:00Z"), latitude: tromso.latitude, longitude: tromso.longitude,
      timeZone: utc)
    XCTAssertNil(moment("Sunrise", in: moments))
    XCTAssertNil(moment("Sunset", in: moments))
    XCTAssertNotNil(moment("Solar noon", in: moments))
  }

  func testPolarNightHasNoSunriseButStillHasTwilight() {
    let moments = SolarTimes.moments(
      on: date("2024-12-21T12:00:00Z"), latitude: tromso.latitude, longitude: tromso.longitude,
      timeZone: utc)
    XCTAssertNil(moment("Sunrise", in: moments))
    XCTAssertNotNil(moment("Nautical dawn", in: moments))
  }

  func testNextMomentSkipsDisabledKindsAndRollsToTomorrow() throws {
    let lateEvening = date("2024-06-21T22:30:00Z")
    let next = try XCTUnwrap(
      SolarTimes.nextMoment(
        after: lateEvening, kinds: [.sunrise], latitude: london.latitude,
        longitude: london.longitude, timeZone: utc))
    XCTAssertEqual(next.label, "Sunrise")
    XCTAssertGreaterThan(next.date, lateEvening)
    XCTAssertLessThan(next.date.timeIntervalSince(lateEvening), 24 * 3600)
  }

  func testNextMomentIsNilWhenNothingIsEnabled() {
    XCTAssertNil(
      SolarTimes.nextMoment(
        after: date("2024-06-21T12:00:00Z"), kinds: [], latitude: london.latitude,
        longitude: london.longitude, timeZone: utc))
  }

  func testCountdownFormatting() {
    let now = date("2024-06-21T12:00:00Z")
    XCTAssertEqual(SolarTimes.countdown(from: now, to: now.addingTimeInterval(14 * 60)), "14m")
    XCTAssertEqual(
      SolarTimes.countdown(from: now, to: now.addingTimeInterval(2 * 3600 + 5 * 60)), "2h 05m")
    XCTAssertEqual(SolarTimes.countdown(from: now, to: now.addingTimeInterval(-60)), "0m")
  }
}
