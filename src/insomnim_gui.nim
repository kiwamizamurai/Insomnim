import insomnim/session
import insomnim/gui_controller
import insomnim/platform/macos_power
import insomnim/platform/appkit_shell

when isMainModule:
  let sessionController = newSessionController(newMacInhibitorFactory())
  let controller = newGuiController(sessionController)
  runAppKit(controller)
