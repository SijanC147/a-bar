import Foundation

/// Which mounted volumes the storage widget draws.
///
/// The bar used to publish every volume `FileManager` returned. The choice now lives in
/// `StorageWidgetSettings.selectedVolumes`, and both the widget and the settings list ask here
/// so they cannot disagree about a disk that just appeared or disappeared.
enum StorageVolumeSelection {

  /// The volume UUID when macOS has one, otherwise the mount path.
  ///
  /// A UUID survives a rename and a remount at a different path. A volume with no UUID is
  /// identified by where it is mounted, which is the only stable string left.
  static func identity(uuid: String?, mountPath: String) -> String {
    let trimmed = uuid?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !trimmed.isEmpty { return trimmed }
    return mountPath
  }

  /// Volumes the bar should draw.
  ///
  /// `nil` shows every mounted volume. A list shows only volumes whose `volumeID` is in it,
  /// in the order the volumes were read. A selected disk that is not mounted is absent here
  /// and stays in the list.
  static func visibleVolumes(
    _ volumes: [StorageVolume], selected: [StorageWidgetSettings.SelectedVolume]?
  ) -> [StorageVolume] {
    guard let selected else { return volumes }
    let ids = Set(selected.map(\.id))
    return volumes.filter { ids.contains($0.volumeID) }
  }

  /// One row in the storage settings list.
  struct Choice: Equatable, Identifiable {
    let id: String
    let name: String
    let isMounted: Bool
    /// True for every mounted disk when `selected` is `nil`, and for each id in an explicit list.
    let isSelected: Bool
  }

  /// Mounted volumes first, then selected volumes that are not connected.
  ///
  /// A disk that is mounted keeps the name macOS reports now. A disk that is only remembered
  /// keeps the name stored with the selection, so the user can still turn it off.
  static func choices(
    mounted: [StorageVolume], selected: [StorageWidgetSettings.SelectedVolume]?
  ) -> [Choice] {
    let selectedIDs = selected.map { Set($0.map(\.id)) }
    var seen = Set<String>()
    var rows: [Choice] = []

    for volume in mounted {
      guard !volume.volumeID.isEmpty, seen.insert(volume.volumeID).inserted else { continue }
      rows.append(
        Choice(
          id: volume.volumeID,
          name: volume.name,
          isMounted: true,
          isSelected: selectedIDs?.contains(volume.volumeID) ?? true
        ))
    }

    for saved in selected ?? [] {
      let id = saved.id.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !id.isEmpty, seen.insert(id).inserted else { continue }
      let name = saved.name.trimmingCharacters(in: .whitespacesAndNewlines)
      rows.append(
        Choice(
          id: id,
          name: name.isEmpty ? id : name,
          isMounted: false,
          isSelected: true
        ))
    }

    return rows
  }

  /// The explicit list that "show every disk" turns into: every disk connected right now.
  ///
  /// Disks connected later are not in this list, so they stay hidden until selected.
  static func explicitSelection(of volumes: [StorageVolume]) -> [StorageWidgetSettings.SelectedVolume] {
    var seen = Set<String>()
    return volumes.compactMap { volume in
      guard !volume.volumeID.isEmpty, seen.insert(volume.volumeID).inserted else { return nil }
      return StorageWidgetSettings.SelectedVolume(id: volume.volumeID, name: volume.name)
    }
  }

  /// The selection after the user flips one disk.
  ///
  /// While every disk is shown (`selected == nil`), turning a disk on changes nothing. Turning
  /// one off records every disk connected at that moment except the one they turned off.
  /// An explicit list gains or loses that one id and is never turned back into `nil`; an empty
  /// list means the user wants no disks, which is not the same as a fresh install.
  static func toggling(
    id: String,
    name: String,
    isOn: Bool,
    selected: [StorageWidgetSettings.SelectedVolume]?,
    mounted: [StorageVolume]
  ) -> [StorageWidgetSettings.SelectedVolume]? {
    let id = id.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !id.isEmpty else { return selected }

    guard var next = selected else {
      if isOn { return nil }
      return explicitSelection(of: mounted).filter { $0.id != id }
    }

    if isOn {
      if !next.contains(where: { $0.id == id }) {
        next.append(
          StorageWidgetSettings.SelectedVolume(
            id: id, name: name.trimmingCharacters(in: .whitespacesAndNewlines)))
      }
    } else {
      next.removeAll { $0.id == id }
    }
    return next
  }

  /// Drop blank ids and repeated ids. `nil` stays `nil`. An empty list stays empty.
  static func normalized(
    _ selected: [StorageWidgetSettings.SelectedVolume]?
  ) -> [StorageWidgetSettings.SelectedVolume]? {
    guard let selected else { return nil }
    var seen = Set<String>()
    return selected.compactMap { volume in
      let id = volume.id.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !id.isEmpty, seen.insert(id).inserted else { return nil }
      return StorageWidgetSettings.SelectedVolume(
        id: id,
        name: volume.name.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    }
  }
}
