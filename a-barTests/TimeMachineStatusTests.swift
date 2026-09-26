import XCTest

/// Time Machine's menu-bar mark is one of three states. The parser has to tell them apart
/// from `tmutil` text alone, and a backup that is still running hides a previous failure.
final class TimeMachineStatusTests: XCTestCase {

  func testAnIdleSessionWithNoFailureIsIdle() {
    let status = """
      Backup session status:
      {
          ClientID = "com.apple.backupd";
          Percent = "-1";
          Running = 0;
      }
      """

    XCTAssertEqual(TimeMachineStatus.state(status: status, phase: "BackupNotRunning"), .idle)
  }

  func testARunningBackupIsInProgress() {
    let status = """
      Backup session status:
      {
          BackupPhase = Copying;
          ClientID = "com.apple.backupd";
          Percent = "0.4";
          Running = 1;
          Stopping = 0;
      }
      """

    XCTAssertEqual(TimeMachineStatus.state(status: status, phase: "Copying"), .running)
  }

  func testABackupPhaseWhileRunningIsStillInProgress() {
    // `currentphase` is the one-word summary. Copying means a backup is underway even when
    // the status dictionary has already flipped Running back to 0.
    let status = """
      Backup session status:
      {
          ClientID = "com.apple.backupd";
          Running = 0;
      }
      """

    XCTAssertEqual(TimeMachineStatus.state(status: status, phase: "Copying"), .running)
  }

  func testAFailedPhaseWithNothingRunningIsFailed() {
    let status = """
      Backup session status:
      {
          BackupPhase = BackupFailed;
          ClientID = "com.apple.backupd";
          Percent = "-1";
          Running = 0;
      }
      """

    XCTAssertEqual(TimeMachineStatus.state(status: status, phase: "BackupNotRunning"), .failed)
  }

  func testAnErrorInTheStatusDictionaryIsAFailedBackup() {
    let status = """
      Backup session status:
      {
          ClientID = "com.apple.backupd";
          Error = "The backup disk is not available.";
          Running = 0;
      }
      """

    XCTAssertEqual(TimeMachineStatus.state(status: status, phase: "BackupNotRunning"), .failed)
  }

  func testAClearedErrorIsNotAFailure() {
    let status = """
      Backup session status:
      {
          ClientID = "com.apple.backupd";
          Error = 0;
          Running = 0;
      }
      """

    XCTAssertEqual(TimeMachineStatus.state(status: status, phase: "BackupNotRunning"), .idle)
  }

  func testARunningBackupWinsOverAPreviousFailure() {
    let status = """
      Backup session status:
      {
          BackupPhase = BackupFailed;
          ClientID = "com.apple.backupd";
          Error = "The backup disk is not available.";
          Running = 1;
      }
      """

    XCTAssertEqual(TimeMachineStatus.state(status: status, phase: "BackupFailed"), .running)
  }

  func testAFailurePhaseFromCurrentPhaseIsFailedWhenNothingIsRunning() {
    let status = """
      Backup session status:
      {
          ClientID = "com.apple.backupd";
          Running = 0;
      }
      """

    XCTAssertEqual(TimeMachineStatus.state(status: status, phase: "BackupFailed"), .failed)
  }

  func testMissingOutputIsIdle() {
    XCTAssertEqual(TimeMachineStatus.state(status: "", phase: ""), .idle)
  }
}
