import ./config

type
  ReleaseCallback* = proc() {.closure.}

  SleepLease* = ref object
    releaseCallback: ReleaseCallback
    active: bool

  InhibitorFactory* = proc(options: InhibitOptions): SleepLease {.closure.}

proc newSleepLease*(callback: ReleaseCallback): SleepLease =
  doAssert callback != nil, "release callback is required"
  SleepLease(releaseCallback: callback, active: true)

proc close*(lease: SleepLease) =
  if lease != nil and lease.active:
    lease.active = false
    lease.releaseCallback()

proc isActive*(lease: SleepLease): bool =
  lease != nil and lease.active
