import ./config
import ./lease
import ./platform/macos_power

proc acquireInhibitor*(options: InhibitOptions = InhibitOptions()): SleepLease =
  let factory = newMacInhibitorFactory()
  factory(options.normalized())

template withSleepInhibitor*(options: InhibitOptions, body: untyped) =
  let inhibitor = acquireInhibitor(options)
  try:
    body
  finally:
    inhibitor.close()
