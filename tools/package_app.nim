import std/os
import std/osproc
import std/strformat

const
  AppName = "Insomnim"
  BundleId = "dev.kiwamizamurai.insomnim"
  ShortVersion = "0.1.0"
  BuildVersion = "1"

proc infoPlist(): string =
  &"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>{BundleId}</string>
  <key>CFBundleName</key><string>{AppName}</string>
  <key>CFBundleExecutable</key><string>insomnim</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleShortVersionString</key><string>{ShortVersion}</string>
  <key>CFBundleVersion</key><string>{BuildVersion}</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
"""

proc main() =
  if not fileExists("bin/insomnim-gui"):
    quit("bin/insomnim-gui not found. Run `nimble gui` first.", 1)

  let appDir = "dist" / (AppName & ".app")
  let contentsDir = appDir / "Contents"
  let macosDir = contentsDir / "MacOS"
  let resourcesDir = contentsDir / "Resources"

  removeDir(appDir)
  createDir(macosDir)
  createDir(resourcesDir)

  writeFile(contentsDir / "Info.plist", infoPlist())
  copyFileWithPermissions("bin/insomnim-gui", macosDir / "insomnim")

  if fileExists("assets/AppIcon.icns"):
    copyFileWithPermissions("assets/AppIcon.icns", resourcesDir / "AppIcon.icns")
  else:
    echo "warning: assets/AppIcon.icns not found, building without an app icon"

  for name in ["menubar-stopped.png", "menubar-active.png"]:
    let src = "assets" / name
    if fileExists(src):
      copyFileWithPermissions(src, resourcesDir / name)
    else:
      echo &"warning: {src} not found, menu bar will fall back to SF Symbols"

  let (output, code) = execCmdEx(&"/usr/bin/codesign --force --deep --sign - {appDir}")
  if code != 0:
    quit("codesign failed:\n" & output, 1)

  echo &"Built {appDir}"

when isMainModule:
  main()
