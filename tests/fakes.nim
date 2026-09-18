import ../src/insomnim/config
import ../src/insomnim/lease

type FakeInhibitor* = ref object
  acquired*: int
  released*: int
  optionsLog*: seq[InhibitOptions]
  failNext*: bool

proc newFakeInhibitor*(): FakeInhibitor =
  FakeInhibitor()

proc factory*(fake: FakeInhibitor): InhibitorFactory =
  result = proc(options: InhibitOptions): SleepLease =
    if fake.failNext:
      fake.failNext = false
      raise newException(OSError, "simulated acquisition failure")
    fake.acquired.inc
    fake.optionsLog.add options
    newSleepLease(proc() = fake.released.inc)
