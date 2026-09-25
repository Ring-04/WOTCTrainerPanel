# WOTC Trainer Panel

An in-game trainer and debug panel for **XCOM 2: War of the Chosen** (Steam, Windows). It adds a
**Trainer Panel** button to the strategy layer and to the tactical HUD. Every change is submitted
through the game's own GameState / HeadquartersOrder paths: no DLL injection, no memory patching, no
AOB scanning, no external trainer, no console command, and no modification of `XCom2.exe`, Steam
files, game configuration or save binaries.

中文说明：[README.zh-CN.md](README.zh-CN.md)

## Status

Version **0.9.0-beta**. The source compiles against the official War of the Chosen SDK with
**0 errors and 0 warnings from this mod** — the 8 warnings the compiler reports come from the SDK's
own DLC content.

**This build has not been played through yet.** Compiling is not the same as working. Everything
below describes what the code is built to do; the in-game checks are still pending. Back up your
saves before you use it on a campaign you care about.

## Requirements

- **XCOM 2: War of the Chosen**, Steam, Windows. The base game on its own will not work
  (`RequiresXPACK=true`).
- The mod ships English (INT) and Simplified Chinese (CHN and CHS) text; the in-game language
  follows your game's language setting.
- No `-allowconsole` flag, no Community Highlander, no other framework or dependency.

## Installation

1. Extract `WOTCTrainerPanel-v0.9.0-beta.zip` anywhere **outside** the game directory.
2. Add the extracted `WOTCTrainerPanel-v0.9.0-beta` folder as a mod directory in your launcher — it
   contains `WOTCTrainerPanel\WOTCTrainerPanel.XComMod`. In AML: Settings → **Mod Directories**, then
   File → **Search for new mods**. Other launchers have their own equivalent.
4. Enable **WOTC Trainer Panel** — one copy only — and launch **XCOM 2: War of the Chosen**.

Step-by-step installation, the exact button positions and the full test checklist are in
[docs/INSTALL-AND-TEST.zh-CN.md](docs/INSTALL-AND-TEST.zh-CN.md) (Chinese).

## Where the panel is

Both entry buttons read **Trainer Panel** (「修改器」 in Chinese) and sit in the top-right corner of
their screen.

| Layer | Appears on | Opens when |
| --- | --- | --- |
| Strategy | Avenger HUD | the top screen is the base facility grid or the strategy map |
| Tactical | tactical HUD | `UITacticalHUD` is up and the tactical GameState is ready |

The strategy panel pauses the geoscape while it is open. `Close`, Esc or gamepad B goes back a level.

## Features

The strategy panel has 8 tabs — Resources, Personnel, Soldiers, Strategy, Items, Tactical, Mission,
Dangerous. The Tactical and Mission tabs are disabled there on purpose: those two panels are opened
from the button inside a mission instead.

- **Resources** — supplies, intel, alien alloys, elerium crystals, elerium cores and XCOM ability
  points, each with `+10 / +50 / +100 / +500 / +1000` or a custom total.
- **Personnel** — +1 engineer and +1 scientist, through the vanilla personnel creation path.
- **Soldiers** — heal every eligible soldier through the vanilla heal order, plus a barracks soldier
  editor: per soldier, 9 fields (HP, aim, mobility, will, hacking, dodge, defence, personal AP, XP)
  with `+1 / +5 / +10 / -1 / -5 / -10`, a template-default reset for the first seven, and a custom
  value for AP and XP.
- **Strategy** — Avatar project progress (`-1 / -2 / -5 / clear`), Avenger power, resistance contact
  capacity, instant completion of research, the proving ground, facility construction and covert
  actions, refunding a build cost, and squad recovery (heal everyone, restore will / clear fatigue).
- **Items** — search by display name or internal name, cycle categories, show or hide story items,
  12 rows per page, and grant a quantity (`+1 / +5 / +10 / +50 / +100 / +500` or a custom amount).
- **Dangerous** — spawn soldiers by class, rank and count (1–20), promote them step by step, and
  pick a rookie's promotion class.
- **Tactical** — 12 toggles (squad invulnerable, selected soldier invulnerable, infinite actions,
  infinite movement, keeping actions after a shot, infinite ammo, no reload, no cooldowns, infinite
  ability and item charges, 100% hit, 100% crit, one-shot kills), a readout of the current unit, and
  5 actions: restore health, +1 action point, +1 movement action point, reload the primary weapon,
  reset ability cooldowns.
- **Mission** — the mission's internal objective records next to the localized objectives the HUD
  shows, completing the selected record or all outstanding ones, finishing the mission as a win or a
  loss, skipping the current AI turn, disabling and re-enabling AI planning when the AI stalls, and
  restarting the current mission through the vanilla flow.

Every write is logged to `Launch.log` with a `[WOTCTrainer]` prefix in an `old value → new value`
form, and the confirmation dialog shows the same pair. Operations that make the game jump to another
screen close the panel first, then let the vanilla flow run.

## Disabled by design

These are off, and the panel says so on screen. They are not missing polish — they could not be made
provably safe, so they were not shipped as switches:

- **Demotion, and forced class changes for promoted soldiers** — the WOTC ability-point and
  persistent-ability state cannot be kept consistent across it.
- **Reviving a dead soldier** — a revival that cannot guarantee that roster state, tactical unit
  state, inventory and mission state all agree would be a fake revival.
- **Teleport** — not implemented in this version.
- **Same-seed mission restart** — the restart uses the vanilla flow; an identical random seed is not
  guaranteed.
- **Forced squad evac** throughout, and **restarting** during Ironman or the tutorial.

## Risks

- **Back up your saves.** The panel writes into your campaign. The writes go through the game's own
  submission APIs and the original value is re-checked before a change is committed, but a trainer is
  still a trainer.
- **Not verified in game yet.** Button placement, Chinese font rendering, layout at other
  resolutions and UI scales, save/load behaviour, runtime API compatibility and compatibility with
  other mods are all unproven.
- **One copy only.** Do not enable two instances of this mod.
- The mod never touches `XCom2.exe`, Steam files, game configuration, launch options or save
  binaries; uninstalling is unchecking the mod and deleting the folder.

## Known limitations

- War of the Chosen only. The base game is not supported.
- The HUD's localized objective list and the mission's internal objective records are **not** a
  one-to-one mapping in the game's data. The panel shows both side by side so you can match them up
  yourself, and never infers one from the other.
- The trainer buttons are placed at fixed offsets from the screen edge and have not been checked at
  other UI scales or resolutions.
- English and Simplified Chinese only.
- Not published on the Steam Workshop; install it as a local mod directory.

## Feedback

Please use the **Issues** tab of this repository. For a bug report include:

- the acceptance item you were following, if any,
- what you did, what you expected, and what actually happened,
- any before/after numbers the panel or the log showed,
- a screenshot for anything visual or layout related,
- your `Launch.log`
  (`%USERPROFILE%\Documents\My Games\XCOM2 War of the Chosen\XComGame\Logs\Launch.log`),
- the other mods you had enabled.

## Building from source

You need the official **XCOM 2: War of the Chosen Development Tools** SDK from Steam and PowerShell.

```powershell
.\tools\Build-Localization.ps1                                   # regenerate INT / CHN / CHS
.\tools\Audit-Localization.ps1                                   # read-only gate, exits non-zero on failure
.\tools\Build.ps1        -SdkRuntime '<isolated copy of the SDK>'
.\tools\Package.ps1      -SdkRuntime '<isolated copy of the SDK>'
```

`Build.ps1` and `Package.ps1` refuse to write into the Steam SDK itself — point them at a copy.
`Audit-Localization.ps1` only reads the repository: it checks key coverage, per-language
completeness, encoding, undeclared references and hardcoded user-visible labels.
