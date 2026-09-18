import std/unittest
import ../src/insomnim/config
import ../src/insomnim/cli
import ../src/insomnim/i18n

suite "parseCliArgs":
  test "no args means forever with idle mode":
    let cfg = parseCliArgs(@[])
    check cfg.action == akForever
    check cfg.inhibit.normalized().modes == {imIdle}

  test "timeout and multiple modes parse together":
    let cfg = parseCliArgs(@["--timeout", "30", "--display", "--system-sleep"])
    check cfg.action == akDuration
    check cfg.durationSeconds == 30
    check cfg.inhibit.modes == {imDisplay, imSystemSleep}

  test "everything after -- is passed through as the child command":
    let cfg = parseCliArgs(@["--display", "--", "rsync", "-av", "--timeout", "src", "dst"])
    check cfg.action == akCommand
    check cfg.command == @["rsync", "-av", "--timeout", "src", "dst"]

  test "non-numeric timeout is rejected":
    expect(CliParseError):
      discard parseCliArgs(@["--timeout", "notanumber"])

  test "-- with no command is rejected":
    expect(CliParseError):
      discard parseCliArgs(@["--"])

  test "timeout and child command together are rejected":
    expect(CliParseError):
      discard parseCliArgs(@["--timeout", "10", "--", "sleep", "1"])

  test "--lang overrides the detected language":
    let cfg = parseCliArgs(@["--lang", "ja", "--timeout", "5"])
    check cfg.lang == langJa
    check cfg.action == akDuration
