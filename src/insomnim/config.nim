type
  InhibitMode* = enum
    imDisplay
    imIdle
    imSystemSleep

  InhibitOptions* = object
    modes*: set[InhibitMode]
    reason*: string

const DefaultReason* = "insomnim (Nim)"

proc normalized*(options: InhibitOptions): InhibitOptions =
  result = options
  if result.modes == {}:
    result.modes = {imIdle}
  if result.reason.len == 0:
    result.reason = DefaultReason
