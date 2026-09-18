import std/os
import std/strutils

type
  Lang* = enum
    langEn
    langJa
    langZh

  StringKey* = enum
    skMenuStartIndefinite
    skMenuStartThirtyMinutes
    skMenuStartOneHour
    skMenuStop
    skMenuSettings
    skMenuQuit
    skMenuLanguage
    skLangEnglish
    skLangJapanese
    skLangChinese
    skWindowTitle
    skStatusOn
    skStatusOff
    skRemainingStopped
    skRemainingIndefinite
    skRemainingPrefix
    skCheckboxDisplay
    skButtonStop
    skAlertTitle
    skCliUsage
    skErrReasonNeedsValue
    skErrLangNeedsValue
    skErrTimeoutNeedsValue
    skErrTimeoutNotNumber
    skErrTimeoutWithCommand
    skErrNoCommandAfterDashDash
    skErrUnknownArgument
    skErrPrefix

const translations: array[StringKey, array[Lang, string]] = [
  skMenuStartIndefinite: [
    langEn: "Start Indefinitely",
    langJa: "無期限で開始",
    langZh: "无限期开始"],
  skMenuStartThirtyMinutes: [
    langEn: "Start for 30 Minutes",
    langJa: "30分間開始",
    langZh: "开始 30 分钟"],
  skMenuStartOneHour: [
    langEn: "Start for 1 Hour",
    langJa: "1時間開始",
    langZh: "开始 1 小时"],
  skMenuStop: [
    langEn: "Stop",
    langJa: "停止",
    langZh: "停止"],
  skMenuSettings: [
    langEn: "Settings...",
    langJa: "設定...",
    langZh: "设置..."],
  skMenuQuit: [
    langEn: "Quit",
    langJa: "終了",
    langZh: "退出"],
  skMenuLanguage: [
    langEn: "Language",
    langJa: "言語",
    langZh: "语言"],
  skLangEnglish: [
    langEn: "English",
    langJa: "English",
    langZh: "English"],
  skLangJapanese: [
    langEn: "日本語",
    langJa: "日本語",
    langZh: "日本語"],
  skLangChinese: [
    langEn: "中文（简体）",
    langJa: "中文（简体）",
    langZh: "中文（简体）"],
  skWindowTitle: [
    langEn: "Insomnim",
    langJa: "Insomnim",
    langZh: "Insomnim"],
  skStatusOn: [
    langEn: "Sleep prevention: ON",
    langJa: "スリープ禁止: ON",
    langZh: "阻止睡眠：开启"],
  skStatusOff: [
    langEn: "Sleep prevention: OFF",
    langJa: "スリープ禁止: OFF",
    langZh: "阻止睡眠：关闭"],
  skRemainingStopped: [
    langEn: "Stopped",
    langJa: "停止中",
    langZh: "已停止"],
  skRemainingIndefinite: [
    langEn: "Indefinite",
    langJa: "無期限",
    langZh: "无限期"],
  skRemainingPrefix: [
    langEn: "Remaining ",
    langJa: "残り ",
    langZh: "剩余 "],
  skCheckboxDisplay: [
    langEn: "Also prevent display sleep",
    langJa: "画面消灯も防ぐ",
    langZh: "同时阻止屏幕休眠"],
  skButtonStop: [
    langEn: "Stop",
    langJa: "停止",
    langZh: "停止"],
  skAlertTitle: [
    langEn: "Insomnim Error",
    langJa: "Insomnim エラー",
    langZh: "Insomnim 错误"],
  skCliUsage: [
    langEn: """insomnim - macOS sleep inhibitor (Insomnia + Nim)

Usage:
  insomnim [options]
  insomnim --timeout SEC [options]
  insomnim [options] -- COMMAND [ARGS...]

Options:
  --timeout SEC     Stop automatically after SEC seconds
  --display         Also prevent the display from sleeping
  --system-sleep    Also request PreventSystemSleep (subject to OS limits)
  --reason TEXT     Reason string reported to the OS (default: "insomnim (Nim)")
  --lang LANG       UI language: en, ja, zh (default: system locale)
  -- COMMAND ARGS   Run COMMAND and inhibit sleep only while it runs
  -h, --help        Show this help
""",
    langJa: """insomnim - macOS スリープ抑止ツール (Insomnia + Nim)

使い方:
  insomnim [options]
  insomnim --timeout SEC [options]
  insomnim [options] -- COMMAND [ARGS...]

オプション:
  --timeout SEC     SEC 秒後に自動停止する
  --display         画面のアイドル消灯も防ぐ
  --system-sleep    PreventSystemSleep も要求する（OS 側の制限を受ける）
  --reason TEXT     OS に報告する理由文字列（既定: "insomnim (Nim)"）
  --lang LANG       UI 言語: en, ja, zh（既定: システムのロケール）
  -- COMMAND ARGS   COMMAND の実行中だけ抑止し、その終了コードを返す
  -h, --help        このヘルプを表示
""",
    langZh: """insomnim - macOS 睡眠阻止工具 (Insomnia + Nim)

用法：
  insomnim [options]
  insomnim --timeout SEC [options]
  insomnim [options] -- COMMAND [ARGS...]

选项：
  --timeout SEC     SEC 秒后自动停止
  --display         同时阻止屏幕休眠
  --system-sleep    同时请求 PreventSystemSleep（受操作系统限制）
  --reason TEXT     报告给系统的原因字符串（默认："insomnim (Nim)"）
  --lang LANG       界面语言：en、ja、zh（默认：跟随系统语言）
  -- COMMAND ARGS   仅在 COMMAND 运行期间阻止睡眠，并返回其退出码
  -h, --help        显示此帮助
"""],
  skErrReasonNeedsValue: [
    langEn: "--reason requires a value",
    langJa: "--reason には値が必要です",
    langZh: "--reason 需要一个值"],
  skErrLangNeedsValue: [
    langEn: "--lang requires a value",
    langJa: "--lang には値が必要です",
    langZh: "--lang 需要一个值"],
  skErrTimeoutNeedsValue: [
    langEn: "--timeout requires a value",
    langJa: "--timeout には値が必要です",
    langZh: "--timeout 需要一个值"],
  skErrTimeoutNotNumber: [
    langEn: "--timeout must be a non-negative integer",
    langJa: "--timeout には0以上の整数を指定してください",
    langZh: "--timeout 必须是非负整数"],
  skErrTimeoutWithCommand: [
    langEn: "--timeout and -- COMMAND cannot be combined",
    langJa: "--timeout と -- COMMAND は同時に指定できません",
    langZh: "--timeout 不能与 -- COMMAND 同时使用"],
  skErrNoCommandAfterDashDash: [
    langEn: "no command given after --",
    langJa: "-- の後にコマンドが指定されていません",
    langZh: "-- 之后未提供命令"],
  skErrUnknownArgument: [
    langEn: "unknown argument: ",
    langJa: "不明な引数です: ",
    langZh: "未知参数："],
  skErrPrefix: [
    langEn: "error: ",
    langJa: "エラー: ",
    langZh: "错误："],
]

var currentLang*: Lang = langEn

proc t*(key: StringKey): string =
  translations[key][currentLang]

proc t*(key: StringKey, lang: Lang): string =
  translations[key][lang]

proc setLang*(lang: Lang) =
  currentLang = lang

proc parseLangCode*(code: string): Lang =
  let c = code.toLowerAscii()
  if c.startsWith("ja"):
    langJa
  elif c.startsWith("zh"):
    langZh
  else:
    langEn

proc detectSystemLang*(): Lang =
  for varName in ["LC_ALL", "LC_MESSAGES", "LANG", "LANGUAGE"]:
    let v = getEnv(varName)
    if v.len > 0:
      return parseLangCode(v)
  langEn
