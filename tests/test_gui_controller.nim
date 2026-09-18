import std/unittest
import std/monotimes
import std/times
import ./fakes
import ../src/insomnim/config
import ../src/insomnim/session
import ../src/insomnim/gui_controller

suite "GuiController":
  test "initial state is OFF, starting indefinite turns it ON":
    let fake = newFakeInhibitor()
    let session = newSessionController(fake.factory())
    let controller = newGuiController(session)
    let now = getMonoTime()

    check controller.viewModel(now).active == false
    check controller.viewModel(now).remaining.kind == rkStopped

    discard controller.handle(gcStartIndefinite, now)
    check controller.viewModel(now).active == true
    check controller.viewModel(now).remaining.kind == rkIndefinite

  test "thirty minute timer shows remaining time and stops after deadline":
    let fake = newFakeInhibitor()
    let session = newSessionController(fake.factory())
    let controller = newGuiController(session)
    let base = getMonoTime()

    discard controller.handle(gcStartThirtyMinutes, base)
    let vm = controller.viewModel(base)
    check vm.remaining.kind == rkTimed
    check vm.remaining.seconds == 1800
    check formatDuration(vm.remaining.seconds) == "30:00"

    discard controller.handle(gcTick, base + initDuration(seconds = 1800))
    check controller.viewModel(base + initDuration(seconds = 1800)).active == false
    check fake.released == 1

  test "toggling display mode keeps remaining time":
    let fake = newFakeInhibitor()
    let session = newSessionController(fake.factory())
    let controller = newGuiController(session)
    let base = getMonoTime()

    discard controller.handle(gcStartThirtyMinutes, base)
    discard controller.handle(gcToggleDisplay, base)

    let vm = controller.viewModel(base)
    check vm.displayEnabled == true
    check vm.remaining.kind == rkTimed
    check vm.remaining.seconds == 1800
    check fake.acquired == 2
    check fake.released == 1

  test "show settings and quit effects":
    let fake = newFakeInhibitor()
    let session = newSessionController(fake.factory())
    let controller = newGuiController(session)
    let now = getMonoTime()

    check controller.handle(gcShowSettings, now) == @[geShowSettings]

    discard controller.handle(gcStartIndefinite, now)
    check controller.handle(gcQuit, now) == @[geTerminate]
    check fake.released == 1
