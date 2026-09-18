import std/monotimes
import std/strformat
import ./config
import ./session

type
  GuiCommand* = enum
    gcStop
    gcStartIndefinite
    gcStartThirtyMinutes
    gcStartOneHour
    gcToggleDisplay
    gcShowSettings
    gcQuit
    gcTick

  GuiEffect* = enum
    geShowSettings
    geTerminate

  RemainingKind* = enum
    rkStopped
    rkIndefinite
    rkTimed

  RemainingDisplay* = object
    case kind*: RemainingKind
    of rkTimed:
      seconds*: uint64
    else:
      discard

  GuiViewModel* = object
    active*: bool
    displayEnabled*: bool
    remaining*: RemainingDisplay
    statusSymbol*: string

  GuiController* = ref object
    session: SessionController

proc newGuiController*(session: SessionController): GuiController =
  GuiController(session: session)

proc handle*(controller: GuiController, command: GuiCommand, now: MonoTime): seq[GuiEffect] =
  result = @[]
  case command
  of gcStop:
    controller.session.stop()
  of gcStartIndefinite:
    controller.session.startIndefinite()
  of gcStartThirtyMinutes:
    controller.session.startFor(1800, now)
  of gcStartOneHour:
    controller.session.startFor(3600, now)
  of gcToggleDisplay:
    var modes = controller.session.snapshot(now).modes
    if imDisplay in modes:
      modes.excl imDisplay
    else:
      modes.incl imDisplay
    controller.session.setOptions(InhibitOptions(modes: modes, reason: DefaultReason))
  of gcShowSettings:
    result.add geShowSettings
  of gcQuit:
    controller.session.close()
    result.add geTerminate
  of gcTick:
    controller.session.tick(now)

proc formatDuration*(total: uint64): string =
  let h = total div 3600
  let m = (total mod 3600) div 60
  let s = total mod 60
  if h > 0:
    &"{h}:{m:02}:{s:02}"
  else:
    &"{m:02}:{s:02}"

proc viewModel*(controller: GuiController, now: MonoTime): GuiViewModel =
  let snap = controller.session.snapshot(now)
  result.displayEnabled = imDisplay in snap.modes
  case snap.kind
  of skInactive:
    result.active = false
    result.remaining = RemainingDisplay(kind: rkStopped)
    result.statusSymbol = "menubar-stopped"
  of skIndefinite:
    result.active = true
    result.remaining = RemainingDisplay(kind: rkIndefinite)
    result.statusSymbol = "menubar-active"
  of skTimed:
    result.active = true
    result.remaining = RemainingDisplay(kind: rkTimed, seconds: snap.remainingSeconds)
    result.statusSymbol = "menubar-active"
