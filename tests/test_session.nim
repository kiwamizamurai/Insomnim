import std/unittest
import std/monotimes
import std/times
import ./fakes
import ../src/insomnim/config
import ../src/insomnim/session

suite "SessionController":
  test "startIndefinite acquires once and stop releases once (idempotent)":
    let fake = newFakeInhibitor()
    let session = newSessionController(fake.factory())
    session.startIndefinite()
    check fake.acquired == 1
    check session.snapshot(getMonoTime()).kind == skIndefinite
    session.stop()
    session.stop()
    check fake.released == 1

  test "timed session expires at deadline":
    let fake = newFakeInhibitor()
    let session = newSessionController(fake.factory())
    let base = getMonoTime()
    session.startFor(30, base)
    check session.snapshot(base + initDuration(seconds = 0)).remainingSeconds == 30

    session.tick(base + initDuration(seconds = 29))
    check session.snapshot(base + initDuration(seconds = 29)).kind == skTimed

    session.tick(base + initDuration(seconds = 30))
    check session.snapshot(base + initDuration(seconds = 30)).kind == skInactive
    check fake.released == 1

  test "reconfiguring while running acquires new lease then releases old, keeps deadline":
    let fake = newFakeInhibitor()
    let session = newSessionController(fake.factory())
    let base = getMonoTime()
    session.startFor(1800, base)
    check fake.acquired == 1

    session.setOptions(InhibitOptions(modes: {imIdle, imDisplay}))
    check fake.acquired == 2
    check fake.released == 1
    check session.snapshot(base).remainingSeconds == 1800
    check session.snapshot(base).modes == {imIdle, imDisplay}

  test "failed reconfiguration keeps old lease and options":
    let fake = newFakeInhibitor()
    let session = newSessionController(fake.factory())
    session.startIndefinite()
    check fake.acquired == 1

    fake.failNext = true
    expect(OSError):
      session.setOptions(InhibitOptions(modes: {imIdle, imDisplay}))

    check fake.released == 0
    check session.snapshot(getMonoTime()).modes == {imIdle}
    check session.snapshot(getMonoTime()).kind == skIndefinite

  test "setting options while inactive does not acquire OS lease":
    let fake = newFakeInhibitor()
    let session = newSessionController(fake.factory())
    session.setOptions(InhibitOptions(modes: {imDisplay}))
    check fake.acquired == 0
    check session.snapshot(getMonoTime()).modes == {imDisplay}

  test "oversized duration raises ValueError without acquiring":
    let fake = newFakeInhibitor()
    let session = newSessionController(fake.factory())
    expect(ValueError):
      session.startFor(high(uint64), getMonoTime())
    check fake.acquired == 0
