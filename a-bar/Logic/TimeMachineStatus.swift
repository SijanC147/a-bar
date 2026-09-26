import Foundation

/// What the Time Machine menu-bar icon is doing.
///
/// A running backup wins over a previous failure, matching the menu bar: the mark spins
/// while a backup is in progress, and the failure glyph only shows once that backup has
/// stopped.
enum TimeMachineBackupState: Equatable {
  case idle
  case running
  case failed
}

/// Reads Time Machine state from the text of public `tmutil` commands.
///
/// The parser does not run `tmutil`. Callers pass the stdout of `tmutil status` and
/// `tmutil currentphase`.
enum TimeMachineStatus {

  static func state(status: String, phase: String) -> TimeMachineBackupState {
    let fields = SessionFields(parsing: status)
    let currentPhase = normalizedPhase(phase)

    if fields.running == true || isActivePhase(currentPhase)
      || (fields.running != false && isActivePhase(fields.backupPhase))
    {
      return .running
    }
    if indicatesFailure(fields.backupPhase) || indicatesFailure(currentPhase) || fields.hasFailure {
      return .failed
    }
    return .idle
  }

  /// `BackupNotRunning` is the idle word `tmutil currentphase` prints. Anything else is a
  /// phase of a backup, unless the phase itself says the backup failed.
  private static func isActivePhase(_ phase: String?) -> Bool {
    guard let phase else { return false }
    return !indicatesFailure(phase)
  }

  private static func indicatesFailure(_ phase: String?) -> Bool {
    guard let phase else { return false }
    let lower = phase.lowercased()
    return lower.contains("fail") || lower.contains("error")
  }

  private static func normalizedPhase(_ raw: String) -> String? {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty || trimmed == "BackupNotRunning" { return nil }
    return trimmed
  }

  /// The dictionary `tmutil status` prints after the "Backup session status:" heading.
  private struct SessionFields {
    var running: Bool?
    var backupPhase: String?
    var hasFailure: Bool

    init(parsing status: String) {
      let dictionary = Self.dictionary(from: status)
      running = Self.runningFlag(dictionary["Running"])
      backupPhase = dictionary["BackupPhase"] as? String
      hasFailure = dictionary.contains { key, value in
        Self.keyMarksFailure(key) && Self.valueMarksFailure(value)
      }
    }

    private static func dictionary(from status: String) -> [String: Any] {
      guard let start = status.firstIndex(of: "{") else { return [:] }
      let body = String(status[start...])
      guard let data = body.data(using: .utf8),
        let object = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
        let dictionary = object as? [String: Any]
      else { return [:] }
      return dictionary
    }

    /// `Running = 1` is a backup in progress. OpenStep plists surface that as a number or a string.
    private static func runningFlag(_ value: Any?) -> Bool? {
      guard let value else { return nil }
      if let number = value as? NSNumber {
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
          return number.boolValue
        }
        return number.intValue != 0
      }
      if let text = value as? String {
        switch text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "yes", "true": return true
        case "0", "no", "false": return false
        default: return nil
        }
      }
      return nil
    }

    private static func keyMarksFailure(_ key: String) -> Bool {
      let lower = key.lowercased()
      return lower.contains("fail") || lower.contains("error")
    }

    /// A zero, false, or empty error is a cleared flag, not a failed backup.
    private static func valueMarksFailure(_ value: Any) -> Bool {
      if let number = value as? NSNumber {
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
          return number.boolValue
        }
        return number.intValue != 0
      }
      if let text = value as? String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != "0"
      }
      if let dictionary = value as? [String: Any] {
        return !dictionary.isEmpty
      }
      if let list = value as? [Any] {
        return !list.isEmpty
      }
      return true
    }
  }
}
