import std/strutils
import ./config
import ./i18n

type
  ActionKind* = enum
    akForever
    akDuration
    akCommand
    akHelp

  CliConfig* = object
    action*: ActionKind
    durationSeconds*: uint64
    command*: seq[string]
    inhibit*: InhibitOptions
    lang*: Lang

  CliParseError* = object of CatchableError

proc parseCliArgs*(args: seq[string]): CliConfig =
  result.action = akForever
  result.lang = detectSystemLang()
  for i, a in args:
    if a == "--lang" and i + 1 < args.len:
      result.lang = parseLangCode(args[i + 1])
      break
  setLang(result.lang)

  var i = 0
  var modes: set[InhibitMode] = {}
  var reason = ""
  var timeoutSet = false

  while i < args.len:
    let a = args[i]
    case a
    of "--help", "-h":
      return CliConfig(action: akHelp, lang: result.lang)
    of "--display":
      modes.incl imDisplay
    of "--system-sleep":
      modes.incl imSystemSleep
    of "--reason":
      inc i
      if i >= args.len:
        raise newException(CliParseError, t(skErrReasonNeedsValue))
      reason = args[i]
    of "--lang":
      inc i
      if i >= args.len:
        raise newException(CliParseError, t(skErrLangNeedsValue))
      result.lang = parseLangCode(args[i])
    of "--timeout":
      inc i
      if i >= args.len:
        raise newException(CliParseError, t(skErrTimeoutNeedsValue))
      try:
        result.durationSeconds = parseBiggestUInt(args[i]).uint64
      except ValueError:
        raise newException(CliParseError, t(skErrTimeoutNotNumber))
      timeoutSet = true
    of "--":
      result.command = args[(i + 1) .. ^1]
      if result.command.len == 0:
        raise newException(CliParseError, t(skErrNoCommandAfterDashDash))
      inc i
      break
    else:
      raise newException(CliParseError, t(skErrUnknownArgument) & a)
    inc i

  if timeoutSet and result.command.len > 0:
    raise newException(CliParseError, t(skErrTimeoutWithCommand))

  result.inhibit = InhibitOptions(modes: modes, reason: reason)

  if result.command.len > 0:
    result.action = akCommand
  elif timeoutSet:
    result.action = akDuration
