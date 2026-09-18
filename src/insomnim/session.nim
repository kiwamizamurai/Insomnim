import std/monotimes
import std/times
import ./config
import ./lease

type
  SessionKind* = enum
    skInactive
    skIndefinite
    skTimed

  SessionController* = ref object
    factory: InhibitorFactory
    currentLease: SleepLease
    options: InhibitOptions
    kind: SessionKind
    deadline: MonoTime

  SessionSnapshot* = object
    kind*: SessionKind
    modes*: set[InhibitMode]
    remainingSeconds*: uint64

const MaxTimedDurationSeconds* = uint64(high(int64) div 1_000_000_000)

proc newSessionController*(factory: InhibitorFactory,
    options: InhibitOptions = InhibitOptions()): SessionController =
  SessionController(factory: factory, options: options.normalized(), kind: skInactive)

proc swapLease(session: SessionController, newLease: SleepLease) =
  let old = session.currentLease
  session.currentLease = newLease
  if old != nil:
    old.close()

proc startIndefinite*(session: SessionController) =
  let newLease = session.factory(session.options)
  session.swapLease(newLease)
  session.kind = skIndefinite

proc startFor*(session: SessionController, seconds: uint64, now: MonoTime) =
  if seconds > MaxTimedDurationSeconds:
    raise newException(ValueError, "duration too large: " & $seconds)
  let newLease = session.factory(session.options)
  session.swapLease(newLease)
  session.deadline = now + initDuration(seconds = seconds.int64)
  session.kind = skTimed

proc setOptions*(session: SessionController, options: InhibitOptions) =
  let normalizedOptions = options.normalized()
  case session.kind
  of skInactive:
    session.options = normalizedOptions
  of skIndefinite, skTimed:
    let newLease = session.factory(normalizedOptions)
    session.swapLease(newLease)
    session.options = normalizedOptions

proc stop*(session: SessionController) =
  if session.currentLease != nil:
    session.currentLease.close()
    session.currentLease = nil
  session.kind = skInactive

proc close*(session: SessionController) =
  session.stop()

proc tick*(session: SessionController, now: MonoTime) =
  if session.kind == skTimed and now >= session.deadline:
    session.stop()

proc ceilSeconds(d: Duration): uint64 =
  let ns = d.inNanoseconds
  if ns <= 0:
    0'u64
  else:
    uint64((ns + 999_999_999) div 1_000_000_000)

proc snapshot*(session: SessionController, now: MonoTime): SessionSnapshot =
  result.kind = session.kind
  result.modes = session.options.modes
  if session.kind == skTimed and now < session.deadline:
    result.remainingSeconds = ceilSeconds(session.deadline - now)
