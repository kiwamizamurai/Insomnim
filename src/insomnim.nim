import std/os
import std/osproc
import std/monotimes
import insomnim/cli
import insomnim/session
import insomnim/i18n
import insomnim/platform/macos_power

var gStopRequested = false
proc onSigint() {.noconv.} = gStopRequested = true

proc printUsage() =
  echo t(skCliUsage)

proc run(): int =
  let parsed =
    try:
      parseCliArgs(commandLineParams())
    except CliParseError as e:
      stderr.writeLine t(skErrPrefix) & e.msg
      return 2

  if parsed.action == akHelp:
    printUsage()
    return 0

  let session = newSessionController(newMacInhibitorFactory(), parsed.inhibit)
  defer: session.close()

  case parsed.action
  of akForever:
    session.startIndefinite()
    setControlCHook(onSigint)
    while not gStopRequested:
      sleep(250)
    return 0
  of akDuration:
    session.startFor(parsed.durationSeconds, getMonoTime())
    while session.snapshot(getMonoTime()).kind != skInactive:
      sleep(250)
      session.tick(getMonoTime())
    return 0
  of akCommand:
    session.startIndefinite()
    let p = startProcess(parsed.command[0], args = parsed.command[1 .. ^1],
                          options = {poParentStreams, poUsePath})
    result = p.waitForExit()
    p.close()
  of akHelp:
    discard

when isMainModule:
  let code = run()
  quit(code)
