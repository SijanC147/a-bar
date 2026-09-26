import XCTest

/// Which disks the storage widget draws, and how the settings list changes that choice.
///
/// `nil` is a fresh install: every disk, including one plugged in later. A list is a choice the
/// user made: disks that are not in it do not appear, a disk that unmounts stays chosen, and a
/// disk that appears later stays hidden.
final class StorageVolumeSelectionTests: XCTestCase {

  private func volume(_ id: String, _ name: String, path: String = "/Volumes/disk") -> StorageVolume {
    StorageVolume(
      name: name, url: URL(fileURLWithPath: path), totalBytes: 100, usedBytes: 40, volumeID: id)
  }

  private func selected(_ id: String, _ name: String) -> StorageWidgetSettings.SelectedVolume {
    StorageWidgetSettings.SelectedVolume(id: id, name: name)
  }

  // MARK: - What the bar draws

  func testAFreshInstallShowsEveryConnectedDisk() {
    let volumes = [volume("boot", "Macintosh HD", path: "/"), volume("backup", "Backup")]

    XCTAssertNil(StorageWidgetSettings().selectedVolumes)
    XCTAssertEqual(StorageVolumeSelection.visibleVolumes(volumes, selected: nil), volumes)
  }

  func testADiskThatIsNotSelectedDoesNotAppear() {
    let boot = volume("boot", "Macintosh HD", path: "/")
    let backup = volume("backup", "Backup")

    let visible = StorageVolumeSelection.visibleVolumes(
      [boot, backup], selected: [selected("boot", "Macintosh HD")])

    XCTAssertEqual(visible, [boot])
  }

  func testAnEmptySelectionShowsNothing() {
    let volumes = [volume("boot", "Macintosh HD", path: "/")]

    XCTAssertTrue(StorageVolumeSelection.visibleVolumes(volumes, selected: []).isEmpty)
  }

  func testADiskThatAppearsLaterIsShownOnlyWhileEveryDiskIsShown() {
    let boot = volume("boot", "Macintosh HD", path: "/")
    let arrived = volume("photos", "Photos")
    let chosen = [selected("boot", "Macintosh HD")]

    XCTAssertEqual(
      StorageVolumeSelection.visibleVolumes([boot, arrived], selected: nil), [boot, arrived])
    XCTAssertEqual(
      StorageVolumeSelection.visibleVolumes([boot, arrived], selected: chosen), [boot])
  }

  func testASelectedDiskThatIsNotMountedDoesNotAppearAndStaysSelected() {
    let boot = volume("boot", "Macintosh HD", path: "/")
    let chosen = [selected("boot", "Macintosh HD"), selected("backup", "Backup")]

    XCTAssertEqual(StorageVolumeSelection.visibleVolumes([boot], selected: chosen), [boot])
    XCTAssertEqual(chosen.map(\.id), ["boot", "backup"])
  }

  func testVisibleVolumesKeepTheOrderTheyWereReadIn() {
    let first = volume("a", "A")
    let second = volume("b", "B")

    XCTAssertEqual(
      StorageVolumeSelection.visibleVolumes(
        [first, second], selected: [selected("b", "B"), selected("a", "A")]),
      [first, second])
  }

  // MARK: - Identity

  func testIdentityPrefersTheVolumeUUID() {
    XCTAssertEqual(
      StorageVolumeSelection.identity(uuid: "UUID-1", mountPath: "/Volumes/Backup"), "UUID-1")
  }

  func testIdentityFallsBackToTheMountPathWhenThereIsNoUUID() {
    XCTAssertEqual(StorageVolumeSelection.identity(uuid: nil, mountPath: "/"), "/")
    XCTAssertEqual(StorageVolumeSelection.identity(uuid: "  ", mountPath: "/Volumes/Backup"),
      "/Volumes/Backup")
  }

  // MARK: - The settings list

  func testChoicesWhileShowingEveryDiskAreTheMountedDisksAllSelected() {
    let choices = StorageVolumeSelection.choices(
      mounted: [volume("boot", "Macintosh HD"), volume("backup", "Backup")], selected: nil)

    XCTAssertEqual(choices.map(\.id), ["boot", "backup"])
    XCTAssertTrue(choices.allSatisfy(\.isSelected))
    XCTAssertTrue(choices.allSatisfy(\.isMounted))
  }

  func testAnUnmountedSelectionStaysInTheListAfterTheDiskDisappears() {
    let choices = StorageVolumeSelection.choices(
      mounted: [volume("boot", "Macintosh HD")],
      selected: [selected("boot", "Macintosh HD"), selected("backup", "Backup")])

    XCTAssertEqual(
      choices,
      [
        StorageVolumeSelection.Choice(id: "boot", name: "Macintosh HD", isMounted: true, isSelected: true),
        StorageVolumeSelection.Choice(id: "backup", name: "Backup", isMounted: false, isSelected: true),
      ])
  }

  func testANewDiskIsListedAndNotSelectedOnceTheUserHasChosenDisks() {
    let choices = StorageVolumeSelection.choices(
      mounted: [volume("boot", "Macintosh HD"), volume("photos", "Photos")],
      selected: [selected("boot", "Macintosh HD")])

    XCTAssertEqual(choices.map(\.isSelected), [true, false])
  }

  func testAMountedDiskKeepsTheNameMacOSReportsNow() {
    let choices = StorageVolumeSelection.choices(
      mounted: [volume("backup", "Backup 2")],
      selected: [selected("backup", "Backup")])

    XCTAssertEqual(choices.first?.name, "Backup 2")
    XCTAssertEqual(choices.first?.isMounted, true)
  }

  // MARK: - Changing the selection

  func testTurningOneDiskOffWhileShowingEveryDiskRecordsTheRest() {
    let mounted = [volume("boot", "Macintosh HD"), volume("backup", "Backup")]

    let next = StorageVolumeSelection.toggling(
      id: "backup", name: "Backup", isOn: false, selected: nil, mounted: mounted)

    XCTAssertEqual(next, [selected("boot", "Macintosh HD")])
  }

  func testTurningADiskOnWhileShowingEveryDiskChangesNothing() {
    let next = StorageVolumeSelection.toggling(
      id: "boot", name: "Macintosh HD", isOn: true, selected: nil,
      mounted: [volume("boot", "Macintosh HD")])

    XCTAssertNil(next)
  }

  func testTurningTheLastSelectedDiskOffShowsNothingRatherThanEveryDisk() {
    let next = StorageVolumeSelection.toggling(
      id: "boot", name: "Macintosh HD", isOn: false,
      selected: [selected("boot", "Macintosh HD")],
      mounted: [volume("boot", "Macintosh HD")])

    XCTAssertEqual(next, [])
  }

  func testTurningANewDiskOnAddsItWithoutDroppingADiskThatIsUnplugged() {
    let next = StorageVolumeSelection.toggling(
      id: "photos", name: "Photos", isOn: true,
      selected: [selected("boot", "Macintosh HD"), selected("backup", "Backup")],
      mounted: [volume("boot", "Macintosh HD"), volume("photos", "Photos")])

    XCTAssertEqual(
      next,
      [selected("boot", "Macintosh HD"), selected("backup", "Backup"), selected("photos", "Photos")])
  }

  func testLimitingToConnectedDisksOmitsDisksThatAppearLater() {
    let chosen = StorageVolumeSelection.explicitSelection(
      of: [volume("boot", "Macintosh HD"), volume("boot", "Macintosh HD")])

    XCTAssertEqual(chosen, [selected("boot", "Macintosh HD")])
    XCTAssertEqual(
      StorageVolumeSelection.visibleVolumes(
        [volume("boot", "Macintosh HD"), volume("photos", "Photos")], selected: chosen
      ).map(\.volumeID),
      ["boot"])
  }

  // MARK: - Saved values

  func testNormalizationDropsBlankAndRepeatedIdsAndKeepsAnEmptyList() {
    XCTAssertNil(StorageVolumeSelection.normalized(nil))
    XCTAssertEqual(StorageVolumeSelection.normalized([]), [])
    XCTAssertEqual(
      StorageVolumeSelection.normalized([
        selected("  disk-a  ", " Backup "),
        selected("disk-a", "Again"),
        selected("   ", "Nope"),
        selected("disk-b", "Photos"),
      ]),
      [selected("disk-a", "Backup"), selected("disk-b", "Photos")])
  }
}
