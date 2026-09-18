import std/monotimes
import darwin/objc/runtime
import darwin/app_kit
import ../gui_controller
import ../i18n

proc setState*(self: NSMenuItem, state: NSControlStateValue) {.objc: "setState:".}

var
  gController: GuiController
  gStatusItem: NSStatusItem
  gSettingsWindow: NSWindow
  gStatusLabel: NSTextField
  gRemainingLabel: NSTextField
  gDisplayCheckbox: NSButton
  gStopButton: NSButton
  gActionTarget: NSObject
  gActionTargetClass: ObjcClass
  gTickTimer: NSTimer
  gPool: NSAutoreleasePool

proc render()
proc showAlert(msg: string)
proc teardown()
proc rebuildMenu()

proc dispatch(command: GuiCommand) =
  try:
    let effects = gController.handle(command, getMonoTime())
    render()
    for e in effects:
      case e
      of geShowSettings:
        gSettingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate()
      of geTerminate:
        teardown()
        NSApp.terminate(nil)
  except CatchableError as err:
    showAlert(err.msg)
    render()

proc dispatchLang(lang: Lang) =
  setLang(lang)
  rebuildMenu()
  render()

proc onStop(self: ID, cmd: SEL, sender: ID) {.cdecl.} = dispatch(gcStop)
proc onStartIndefinite(self: ID, cmd: SEL, sender: ID) {.cdecl.} = dispatch(gcStartIndefinite)
proc onStartThirtyMinutes(self: ID, cmd: SEL, sender: ID) {.cdecl.} = dispatch(gcStartThirtyMinutes)
proc onStartOneHour(self: ID, cmd: SEL, sender: ID) {.cdecl.} = dispatch(gcStartOneHour)
proc onToggleDisplay(self: ID, cmd: SEL, sender: ID) {.cdecl.} = dispatch(gcToggleDisplay)
proc onShowSettings(self: ID, cmd: SEL, sender: ID) {.cdecl.} = dispatch(gcShowSettings)
proc onQuit(self: ID, cmd: SEL, sender: ID) {.cdecl.} = dispatch(gcQuit)
proc onTick(self: ID, cmd: SEL, sender: ID) {.cdecl.} = dispatch(gcTick)
proc onSetLangEn(self: ID, cmd: SEL, sender: ID) {.cdecl.} = dispatchLang(langEn)
proc onSetLangJa(self: ID, cmd: SEL, sender: ID) {.cdecl.} = dispatchLang(langJa)
proc onSetLangZh(self: ID, cmd: SEL, sender: ID) {.cdecl.} = dispatchLang(langZh)

proc statusImage(resourceName: string): NSImage =
  # Prefer the bundled Waking Moon glyphs; fall back to SF Symbols when running
  # a dev build (e.g. `bin/insomnim-gui` directly) without a Resources folder.
  let path = NSBundle.mainBundle().pathForResource(resourceName, "png")
  if path != nil and path.len > 0:
    let img = NSImage.alloc().initWithContentsOfFile(path)
    if img != nil:
      img.setSize(NSMakeSize(18, 18))
      return img
  let fallback = if resourceName == "menubar-active": "cup.and.saucer.fill" else: "moon.zzz"
  NSImage.imageWithSystemSymbolName(fallback, nil)

proc remainingText(r: RemainingDisplay): string =
  case r.kind
  of rkStopped: t(skRemainingStopped)
  of rkIndefinite: t(skRemainingIndefinite)
  of rkTimed: t(skRemainingPrefix) & formatDuration(r.seconds)

proc render() =
  if gController.isNil:
    return
  let vm = gController.viewModel(getMonoTime())

  let button = gStatusItem.button()
  let img = statusImage(vm.statusSymbol)
  when defined(insomnimDebug):
    stderr.writeLine "render: active=" & $vm.active & " symbol=" & vm.statusSymbol &
      " button=" & $(button != nil) & " img=" & $(img != nil)
  if img != nil:
    img.setTemplate(true)
    button.image = img
    button.title = ""
  else:
    button.image = nil
    button.title = (if vm.active: "☕" else: "Zz")

  if gStatusLabel != nil:
    gStatusLabel.setStringValue(if vm.active: t(skStatusOn) else: t(skStatusOff))
  if gRemainingLabel != nil:
    gRemainingLabel.setStringValue(remainingText(vm.remaining))
  if gDisplayCheckbox != nil:
    gDisplayCheckbox.setTitle(t(skCheckboxDisplay))
    gDisplayCheckbox.setState(
      if vm.displayEnabled: NSControlStateValueOn else: NSControlStateValueOff)
  if gStopButton != nil:
    gStopButton.setTitle(t(skButtonStop))
  if gSettingsWindow != nil:
    gSettingsWindow.setTitle(t(skWindowTitle))

proc showAlert(msg: string) =
  let alert = NSAlert.alloc().init()
  alert.setMessageText(t(skAlertTitle))
  alert.setInformativeText(msg)
  alert.setAlertStyle(NSAlertStyleWarning)
  alert.runModal()

proc teardown() =
  if gTickTimer != nil:
    gTickTimer.invalidate()
    gTickTimer = nil
  if gStatusItem != nil:
    NSStatusBar.systemStatusBar().removeStatusItem(gStatusItem)
    gStatusItem = nil

proc buildActionTarget() =
  addClass("InsomnimActionTarget", "NSObject", gActionTargetClass):
    addMethod("stop:", onStop)
    addMethod("startIndefinite:", onStartIndefinite)
    addMethod("startThirtyMinutes:", onStartThirtyMinutes)
    addMethod("startOneHour:", onStartOneHour)
    addMethod("toggleDisplay:", onToggleDisplay)
    addMethod("showSettings:", onShowSettings)
    addMethod("quit:", onQuit)
    addMethod("tick:", onTick)
    addMethod("setLangEn:", onSetLangEn)
    addMethod("setLangJa:", onSetLangJa)
    addMethod("setLangZh:", onSetLangZh)
  gActionTarget = cast[NSObject](createInstance(gActionTargetClass, 0))

proc addMenuItem(menu: NSMenu, title: string, action: string): NSMenuItem =
  result = NSMenuItem.alloc().initWithTitle(title, selector(action), "")
  result.setTarget(cast[ID](gActionTarget))
  menu.addItem(result)

proc buildLanguageMenu(): NSMenu =
  result = NSMenu.alloc().initWithTitle(t(skMenuLanguage))
  let enItem = result.addMenuItem(t(skLangEnglish), "setLangEn:")
  let jaItem = result.addMenuItem(t(skLangJapanese), "setLangJa:")
  let zhItem = result.addMenuItem(t(skLangChinese), "setLangZh:")
  enItem.setState(if currentLang == langEn: NSControlStateValueOn else: NSControlStateValueOff)
  jaItem.setState(if currentLang == langJa: NSControlStateValueOn else: NSControlStateValueOff)
  zhItem.setState(if currentLang == langZh: NSControlStateValueOn else: NSControlStateValueOff)

proc buildMenu(): NSMenu =
  result = NSMenu.alloc().initWithTitle(t(skWindowTitle))
  discard result.addMenuItem(t(skMenuStartIndefinite), "startIndefinite:")
  discard result.addMenuItem(t(skMenuStartThirtyMinutes), "startThirtyMinutes:")
  discard result.addMenuItem(t(skMenuStartOneHour), "startOneHour:")
  result.addItem(NSMenuItem.separatorItem())
  discard result.addMenuItem(t(skMenuStop), "stop:")
  result.addItem(NSMenuItem.separatorItem())

  let langItem = NSMenuItem.alloc().initWithTitle(t(skMenuLanguage), nil, "")
  langItem.setSubmenu(buildLanguageMenu())
  result.addItem(langItem)

  discard result.addMenuItem(t(skMenuSettings), "showSettings:")
  discard result.addMenuItem(t(skMenuQuit), "quit:")

proc rebuildMenu() =
  if gStatusItem != nil:
    gStatusItem.menu = buildMenu()

proc buildStatusItem() =
  gStatusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
  gStatusItem.menu = buildMenu()

proc buildSettingsWindow() =
  let rect = NSMakeRect(0, 0, 300, 170)
  gSettingsWindow = NSWindow.alloc().initWithContentRect(
    rect,
    NSWindowStyleMaskTitled or NSWindowStyleMaskClosable,
    NSBackingStoreBuffered,
    false)
  gSettingsWindow.setTitle(t(skWindowTitle))
  gSettingsWindow.center()

  let content = NSView.alloc().initWithFrame(rect)
  gSettingsWindow.setContentView(content)

  gStatusLabel = cast[NSTextField](NSTextField.alloc().initWithFrame(NSMakeRect(20, 124, 260, 22)))
  gStatusLabel.setEditable(false)
  gStatusLabel.setBezeled(false)
  gStatusLabel.setDrawsBackground(false)
  content.addSubview(gStatusLabel)

  gRemainingLabel = cast[NSTextField](NSTextField.alloc().initWithFrame(NSMakeRect(20, 98, 260, 22)))
  gRemainingLabel.setEditable(false)
  gRemainingLabel.setBezeled(false)
  gRemainingLabel.setDrawsBackground(false)
  content.addSubview(gRemainingLabel)

  gDisplayCheckbox = cast[NSButton](NSButton.alloc().initWithFrame(NSMakeRect(20, 62, 260, 24)))
  cast[NSButtonCell](gDisplayCheckbox.cell()).setButtonType(NSButtonTypeSwitch)
  gDisplayCheckbox.setTitle(t(skCheckboxDisplay))
  gDisplayCheckbox.setTarget(gActionTarget)
  gDisplayCheckbox.setAction(selector("toggleDisplay:"))
  content.addSubview(gDisplayCheckbox)

  gStopButton = cast[NSButton](NSButton.alloc().initWithFrame(NSMakeRect(20, 20, 100, 30)))
  gStopButton.setTitle(t(skButtonStop))
  gStopButton.setTarget(gActionTarget)
  gStopButton.setAction(selector("stop:"))
  content.addSubview(gStopButton)

proc runAppKit*(guiController: GuiController) =
  gController = guiController
  gPool = NSAutoreleasePool.alloc().init()

  setLang(detectSystemLang())

  discard NSApplication.sharedApplication()
  NSApp.setActivationPolicy(NSApplicationActivationPolicyAccessory)

  buildActionTarget()
  buildStatusItem()
  buildSettingsWindow()

  gTickTimer = NSTimer.scheduledTimerWithTimeInterval(
    1.0, gActionTarget, selector("tick:"), nil, true)

  render()
  NSApp.run()
