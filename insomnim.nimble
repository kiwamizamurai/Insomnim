version       = "0.1.0"
author        = "kiwamizamurai"
description   = "macOS sleep-inhibitor CLI/GUI built with Nim (Insomnia + Nim)"
license       = "MIT"
srcDir        = "src"

requires "nim >= 2.2.0"
requires "https://github.com/yglukhov/darwin.git#f2a16caab8f4cac9f821262ec6b7942ee7795dd4"

task test, "Run unit tests":
  exec "nim c -r --mm:orc -o:bin/test_cli tests/test_cli.nim"
  exec "nim c -r --mm:orc -o:bin/test_session tests/test_session.nim"
  exec "nim c -r --mm:orc -o:bin/test_gui_controller tests/test_gui_controller.nim"

task release, "Build optimized CLI binary":
  exec "nim c -d:release --mm:orc -o:bin/insomnim src/insomnim.nim"

task gui, "Build optimized GUI binary":
  exec "nim c -d:release --mm:orc -o:bin/insomnim-gui src/insomnim_gui.nim"

task app, "Build .app bundle with ad-hoc codesign":
  exec "nimble gui"
  exec "nim c -r tools/package_app.nim"
