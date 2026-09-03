# Edit Mode snapping validation

## Evidence boundary

- Target: Retail 12.1.0.69587, interface `120100`; version `0.1.0` is unchanged.
- The installed Battle.net `.build.info` identifies 12.1.0.69587. An in-game
  `GetBuildInfo()` result has not been captured for this change.
- Source reference: [Gethe/wow-ui-source at
  8ea15b61e45c0ed4eba01439c90757f86eb78d34](https://github.com/Gethe/wow-ui-source/tree/8ea15b61e45c0ed4eba01439c90757f86eb78d34),
  including its [version.txt](https://github.com/Gethe/wow-ui-source/blob/8ea15b61e45c0ed4eba01439c90757f86eb78d34/version.txt)
  and `Blizzard_EditMode/Shared` manager, grid, selection, and magnetism code.
- Native bottom clearance is 25 UI units: `EditModeDialogs.xml` supplies 40
  units of height padding and a 15-unit title inset, while `ResizeLayoutMixin`
  in `Blizzard_SharedXML/LayoutFrame.lua` sizes the frame from its child extents.
- Snapping is placement-only. Ironfur Tracker remains outside Blizzard's system
  registry and layout storage. No linked anchors or reciprocal native-to-addon
  snapping are part of this change.
- Off-client verification passed. The matrix below distinguishes that evidence
  from unperformed in-game observations. Source inspection and Lua stubs cannot
  establish visual accuracy, taint safety, protected behavior, or release readiness.

## Automated checks

- `lua tests/runner.lua`: 39 tests passed, including 15 snapping regressions,
  drag-panel visibility and bottom-clearance regressions, and the existing tracker/settings suite,
  loading all runtime files in TOC order.
- `powershell -File tests/native_source_check.ps1`: eight placement scenarios
  passed using the pinned Blizzard magnetism and geometry source with frame
  stubs. This optional check downloads that exact source without saving it.
  It covers double-grid snaps, screen padding, element edges/corners, snap range,
  UI scale, scaled targets, expanded selections, and independent positioning.
- `luac -p`: all nine runtime/test Lua files parsed with desktop Lua 5.4.6.
- `git diff --check`: passed. Git reports only its normal LF-to-CRLF notices.
- SavedVariables retain schema 1 and account-wide ownership. Existing numeric
  offsets remain valid; fractional offsets are now preserved rather than rounded.

## Gameplay-context matrix

| Context or transition | Applicability | Expected behavior | Evidence and status |
| --- | --- | --- | --- |
| Settings panel opens/reopens at supported UI scales | Required | Retain 25 UI units below the last button, matching the native settings panel; controls and reset behavior remain unchanged | Anchor-derived regression reproduced 12 units before the fix and passed with 25 afterward; rendered spacing unverified |
| Settings open, bar drag starts/continues/releases, editing ends | Required | Keep the settings panel visible during movement and after release; preserve input commit behavior; close it on cancellation or Edit Mode exit | Regression reproduced before the fix and passed afterward, including seven cancellation paths; live appearance unverified |
| Enable Snap off, on, and changed during a drag | Required | Off permits free placement and clears guides; on previews the current eligible candidate and snaps only when released | Mock regression passed; native control interaction unverified |
| Show Grid on/off and Grid Spacing changes | Required | Current visible grid lines determine candidates; a hidden grid contributes none, while element and screen candidates remain available | Native-source grid registration/removal passed; actual grid controls unverified |
| Screen center/edges and competing candidates | Required | Native candidate priority and thresholds produce a stable preview and matching final placement | Native-source placement/range scenarios passed; live pointer behavior unverified |
| Native element edge/corner alignment, scaled frames, expanded selection bounds | Required | Use current visible selection geometry; exclude ineligible or hidden targets; preview and final placement agree | Native-source geometry scenarios and mock filtering passed; native frame behavior unverified |
| Move or resize a target after snapping Ironfur | Required | Ironfur retains its saved screen-relative position and does not follow the target | Independent-position and anchor-history assertions passed; live layout behavior unverified |
| Drag a native element near Ironfur | Required | Ironfur is not registered as a native snap target; Blizzard's normal behavior remains intact | Registry/preview isolation assertions passed; live behavior unverified |
| Combat begins while dragging; repeated combat-state events; combat ends | Evidence-gated | End drag and guide work safely, keep a usable placement, never move native elements, and allow a fresh drag after combat | Mock interruption passed; actual lockdown, taint, restricted encounters, and repeated combat transitions unverified |
| Edit Mode exit, selection hiding, hidden UI, or Guardian spec loss during drag | Required | Stop interaction and guides without stale callbacks; restore the proper live/hidden bar state; recover on re-entry without reload | Mock cancellation cases passed; actual parent hide/show transitions unverified |
| Manager or grid unavailable, becomes available late, or is replaced | Required | Free placement remains usable where possible; do not use stale native references; subsequent valid Edit Mode entry recovers without duplicate hooks | Mock unavailable/restored dependencies passed; manager recreation and client lifecycle unverified |
| Missing, non-finite, delayed, or secret geometry | Required | Skip unusable candidates without arithmetic on secret values or persisting them; clear stale guides and recover when valid data returns | Mock invalid-data/recovery cases passed; real restricted data unverified |
| UI scale/resolution change; resize bar; drag at screen boundary | Required | Use current coordinate scale and bar bounds, retain precise placement where valid, and keep the bar on screen | Source scale/edge scenarios and mock resize/scale refresh passed; live resolutions/scales unverified |
| Clean/current/corrupt SavedVariables; reload, relog, zone or instance loading | Required | Preserve valid size/position, recover only invalid fields, and restore independent account-wide placement without native layout storage | Defaults/field recovery and position assertions passed; actual reload/relog/loading unverified |
| Native layout switch, Save, Revert, import, or export | Required | Native layout operations do not save, revert, export, or attach Ironfur's independently stored position | Registry isolation passed and no layout-storage writes found in code audit; live workflows unverified |
| Repeated drags, event bursts, long session | Required | One active drag/preview at a time; no duplicate frames/hooks or snapping update work when idle; newest valid geometry wins | Mock repetition and idle-cleanup assertions passed; representative long session unverified |
| Vehicle, taxi, override/possess UI, pet battle, cinematic/movie, Settings, or quick-keybind overlap | Evidence-gated | Whenever Edit Mode or its selections disappear, end snapping interaction; recover when normal editing returns | Actual client overlay/control transitions unverified |
| Live Bear display, Cat retention, spec/talent/loadout/spellbook changes, expiry, death/resurrection | Required | Existing tracker behavior remains unchanged before, during, and after Edit Mode interaction | Existing 22 tests passed; uncovered transitions and live gameplay regression unverified |
| Charges, cooldown availability/reset, target/focus/mouseover changes, roster or group role | Not applicable | These are not inputs to snapping or position persistence; successful player casts remain the tracker's timer input | No new snapping tests required for these unrelated sources |

For each in-game pass, record the exact `GetBuildInfo()` output, context,
entry/exit and recovery observed, and Lua errors, taint, blocked/forbidden actions,
or secret-value failures inspected. No client installation, client control, or
real SavedVariables modification has been performed for this validation record.

## Package check

Verified a no-upload archive with exactly eight entries: the matching
`IronfurTracker` folder/TOC, README, and all six runtime Lua files with correct
path casing. Tests, repository instructions, and validation documentation are
excluded.

- Archive: `IronfurTracker-0.1.0-unreleased.zip`
- SHA-256: `0FE2A724447A625B1DB09547576687575B5646AB9BAE2DFB2D9A5BE3F0D08DB6`
- This refreshed archive includes the bottom-gap and drag-panel visibility
  fixes; earlier test archives do not include the bottom-gap fix.
- The artifact has not been installed or tested in game. No tags, pushes,
  uploads, or publishing were performed. Installation and the applicable client
  matrix passes remain required before a release-readiness claim.
