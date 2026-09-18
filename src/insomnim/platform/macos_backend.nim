import ../config

{.passL: "-framework IOKit -framework CoreFoundation".}

type
  IOReturn = int32
  IOPMAssertionID = uint32
  CFStringRef = pointer
  CFAllocatorRef = pointer

const
  kIOReturnSuccess: IOReturn = 0
  kCFStringEncodingUTF8: uint32 = 0x08000100
  kIOPMAssertionLevelOn: uint32 = 255

proc CFStringCreateWithCString(alloc: CFAllocatorRef, cStr: cstring,
    encoding: uint32): CFStringRef {.importc, header: "<CoreFoundation/CFString.h>".}
proc CFRelease(cf: pointer) {.importc, header: "<CoreFoundation/CFBase.h>".}
proc IOPMAssertionCreateWithName(assertionType: CFStringRef,
    assertionLevel: uint32, assertionName: CFStringRef,
    assertionID: ptr IOPMAssertionID): IOReturn
    {.importc, header: "<IOKit/pwr_mgt/IOPMLib.h>".}
proc IOPMAssertionRelease(assertionID: IOPMAssertionID): IOReturn
    {.importc, header: "<IOKit/pwr_mgt/IOPMLib.h>".}

type Token* = object
  assertionIds*: seq[IOPMAssertionID]

proc newCFString(s: string): CFStringRef =
  result = CFStringCreateWithCString(nil, s.cstring, kCFStringEncodingUTF8)
  if result == nil:
    raise newException(OSError, "CFStringCreateWithCString returned nil")

proc modeToAssertionType(mode: InhibitMode): string =
  case mode
  of imIdle: "PreventUserIdleSystemSleep"
  of imDisplay: "PreventUserIdleDisplaySleep"
  of imSystemSleep: "PreventSystemSleep"

proc createAssertion(assertionType, reason: string): IOPMAssertionID =
  let typeRef = newCFString(assertionType)
  defer: CFRelease(typeRef)
  let reasonRef = newCFString(reason)
  defer: CFRelease(reasonRef)
  var id: IOPMAssertionID
  let rc = IOPMAssertionCreateWithName(typeRef, kIOPMAssertionLevelOn, reasonRef, id.addr)
  if rc != kIOReturnSuccess:
    raise newException(OSError, "IOPMAssertionCreateWithName failed: " & $rc)
  id

proc release*(token: var Token) =
  for id in token.assertionIds:
    discard IOPMAssertionRelease(id)
  token.assertionIds.setLen(0)

proc acquire*(options: InhibitOptions): Token =
  let effective = options.normalized()
  var token: Token
  try:
    for mode in effective.modes:
      token.assertionIds.add createAssertion(modeToAssertionType(mode), effective.reason)
  except CatchableError:
    token.release()
    raise
  token
