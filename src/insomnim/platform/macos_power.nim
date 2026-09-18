import ./macos_backend
import ../config
import ../lease

proc newMacInhibitorFactory*(): InhibitorFactory =
  result = proc(options: InhibitOptions): SleepLease =
    var token = macos_backend.acquire(options)
    newSleepLease(proc() = token.release())
