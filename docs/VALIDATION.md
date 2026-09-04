# EnhanceQoL settings handoff validation

- Scope: Selecting Ironfur closes the optional EnhanceQoL settings dialog, including repeated selections and recovery after combat.
- Persistence: No saved-setting changes.
- Contracts: Optional public HideSettingsDialog on the inspected EnhanceQoLEditMode provider; existing native selection boundary.
- Target: Retail live 12.1.0.69587, interface 120100; TOC version 0.1.0 unchanged.
- Source: Gethe/wow-ui-source live commit 8ea15b61e45c0ed4eba01439c90757f86eb78d34, version.txt 12.1.0.69587.
- All 68 off-client tests pass from this complete commit snapshot; its Lua files parse successfully.
- Tests load runtime files in TOC order with addon varargs and strict stubs. They do not establish client rendering or combat safety.

| Context | Evidence |
| --- | --- |
| Fresh, migrated, malformed and reset settings as applicable | Covered by the corresponding off-client persistence and control regressions |
| Editor selection, inputs, previews, repeat changes and recovery | Corresponding off-client interaction and lifecycle regressions pass |
| Login/reload, native menus/pickers, UI scale, scrolling, combat/taint and restricted encounters | Unverified in Retail 12.1.0.69587; no live GetBuildInfo capture or client control was performed |
| Live tracking, forms, talents, loading screens and restricted data | Existing regression coverage retained; actual gameplay contexts remain unverified |

No installation, real SavedVariables changes, tags, pushes or publishing were performed. This snapshot is not a release-readiness claim.

---

The following baseline evidence is historical and predates this commit scope.

# Appearance, Druid visibility, and Edit Mode highlight validation

## Current change and proof boundary

The current implementation adds grouped appearance settings, shared-media bar
and border selectors, and default empty-bar visibility for every Druid in Bear
Form. The unfilled background is unchanged. Settings remain account-wide.
The follow-up adds a settings-panel eye and observes EnhanceQoL's global eye to
hide the selection highlight without hiding the bar sample, settings, or drag
target. Highlight visibility is temporary and is not saved.
The tick-height correction decouples markers from decorative border geometry.
The supplied screenshot shows short markers in the live bar, but does not
establish the client's exact build or saved border settings.
The latest settings update replaces color buttons with clickable bordered
swatches, keeps texture previews only in opened menus, and adds a Tick section
for RGBA color and width. Defaults retain the existing pale markers at width 2.

- Target: Retail live 12.1.0.69587, repository-declared interface `120100`.
  The installed `Wow.exe` file and product versions match this build.
- Pinned source: Gethe/wow-ui-source `live`, commit
  [8ea15b61e45c0ed4eba01439c90757f86eb78d34](https://github.com/Gethe/wow-ui-source/tree/8ea15b61e45c0ed4eba01439c90757f86eb78d34),
  whose `version.txt` is `12.1.0.69587`.
- No live `GetBuildInfo()` capture, installation, client control, or real
  SavedVariables changes were performed. Source and stubs are not in-game proof.
- Version `0.1.0` and interface declaration are unchanged. Classic, PTR, and
  additional builds are outside this change's compatibility claim.
- The suite passed 62 tests before the latest settings update. Current results
  and archive evidence are recorded below after integration checks.

## API and lifecycle evidence

All paths below are relative to the pinned source's `Interface/AddOns` directory.

| Contract | Build-matched source | Design consequence |
| --- | --- | --- |
| Player class, cast event payload, secret predicates | `Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` and `SecretPredicatesDocumentation.lua` | Class token determines eligibility; no specialization query. Player cast payloads may still be restricted by individual spell flags, so secret values are ignored |
| Form IDs and existing form reader | `Blizzard_FrameXMLBase/Constants.lua`, Cat 1 and Bear 5 | Preserve the existing `GetShapeshiftFormID()` boundary; secret form values suspend rendering. Full legacy reader behavior across forms remains a live evidence gate |
| Known spells and spellbook changes | `Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua` | `C_SpellBook.IsSpellKnown` defaults to the player bank; `SPELLS_CHANGED` has no payload and refreshes retention/proc state |
| Native color picker | `Blizzard_ColorPickerFrame/Mainline/ColorPickerFrame.lua` and its Mainline TOC | Direct RGBA alpha, live callbacks, cancel rollback, ownership through `extraInfo`; enabled game/mainline module is not load-on-demand |
| Clickable color swatches and tick tint | `Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua`, `SimpleTextureBaseAPIDocumentation.lua`, and `SimpleScriptRegionResizingAPIDocumentation.lua` | Existing `CreateTexture`, `SetColorTexture`, sizing and anchor contracts on ordinary addon-owned regions; no additional template or protected integration. A separate opaque gray border surrounds each clickable color texture |
| Menus and pooled previews | `Blizzard_Menu/DropdownButton.lua`, `MenuTemplates.lua`, `Compositor.lua` | Native radio menus, scrollable lists, attached textures/templates, and per-dropdown closure |
| Scrollable settings | `Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua`, `MinimalScrollBar.lua`/XML | Native ScrollFrame/MinimalScrollBar synchronization; fixed reset-button clearance |
| Textured outline | `Blizzard_SharedXML/Backdrop.lua` and `Backdrop.xml` | `BackdropTemplate`, `edgeFile`, `edgeSize`, RGBA tint; separate frame anchors implement offset. Nonpositive size clears the backdrop instead of invoking the client's default edge size |
| Tick dimensions and placement | `Blizzard_APIDocumentationGenerated/SimpleScriptRegionResizingAPIDocumentation.lua`, `SetSize` and `SetPoint` | Existing calls use UI-unit dimensions and offsets on addon-owned textures. The fix changes their geometry inputs only; no new protected frame or secure attribute interaction |
| Native Edit Mode selection lifecycle | `Blizzard_EditMode/Shared/EditModeManager.lua` and `EditModeSystemTemplates.lua` | Native selection hiding suspends interaction; highlight opacity is independent. `ShowSelected` and `ShowHighlighted` do not reset alpha |
| Eye texture and tooltip ownership | `Blizzard_APIDocumentationGenerated/SimpleButtonAPIDocumentation.lua`, `SimpleTextureBaseAPIDocumentation.lua`, and `Blizzard_GameTooltip/Mainline/GameTooltip.lua` | A normal button texture accepts sprite UVs; close only the eye's owned tooltip and do not revive it after mouse leave |

[Blizzard's 12.1 aura announcement](https://us.forums.blizzard.com/en/wow/t/addons-and-auras-in-curse-of-ula%E2%80%99tek/2317456/)
describes display-only filtered aura APIs. This change keeps observed-cast timer
estimates and does not reconstruct restricted aura data. Zero means zero locally
tracked applications, including immediately after reload while an old buff may
still exist.

Library provenance, licenses, selected-media resolution, and the known-asset
check's limits are recorded in [LIBRARIES.md](LIBRARIES.md).

### Optional EnhanceQoL integration

The installed `EnhanceQoL/libs/EnhanceQoLEditMode/EnhanceQoLEditMode.lua` declares
`EnhanceQoLEditMode-1.0` minor `21000001`. Its global eye changes native selection
alpha and writes `internal.managerEyeButton.allHidden` after applying its action
(lines 989-1069). It exposes no global-highlight callback. The narrow observer in
EditMode therefore accepts only that verified library minor and post-hooks the
eye's `OnClick`, reading the completed action's boolean. It does not register
Ironfur with EnhanceQoL or change its frames, layout storage, or visibility state.

The public `RegisterCallback("enter", callback)` runs after the provider resets
its eye on entry (lines 4126-4135); a post-hook on public `AddFrame` discovers an
eye created later by `EnsureDialog` (lines 4289-4296). Repeated discovery retains a
local choice. A newly attached eye supplies initial state, and each subsequent
local or global click wins. Existing callbacks are reused and obsolete buttons
are ignored. Absent or unsupported library versions leave the local eye usable;
their global toggle integration is unsupported until its contract is reviewed.
No additional dependency is bundled.

The settings eye uses the installed library's demonstrated `LFG-Eye` texture
layout: 512 by 256, 64 by 64 frames, open frame 0 and closed frame 4. The native
texture methods are build-matched; actual asset rendering and hit targets still
require an in-game check. Highlight opacity is on an addon-owned ordinary frame,
with no protected attributes or native frame mutation. Exact combat and taint
behavior remain unverified.

## State and upgrade contract

- Config owns schema 3, defaults, validation, and durable choices. Additive
  validation preserves schema 1 size/position and schema 2 appearance, including
  fractional offsets. Tick width defaults to 2 in the range 1-20; tick color
  defaults to RGBA `(1, 0.94, 0.72, 1)`. Numeric fields and color channels are
  validated before the schema advances; existing valid choices are retained.
  Missing visibility defaults to true; explicit false is preserved.
- Invalid color channels recover independently. Missing media providers leave
  the selected name intact and use Default until that name is registered.
- Core owns normalized Druid/form state and display decisions. Tracker remains
  the only owner of real application/proc timers. Static editor samples never
  enter Tracker and do not require an animation driver.
- Settings owns controls, picker transactions, and menu cleanup; EditMode owns
  selection, dragging, and Blizzard hooks. Native layout storage is untouched.
- EditMode also owns temporary highlight visibility. Alpha zero preserves the
  preview and drag surface; native selection suspension still closes settings
  and stops dragging. The local flag resets on exit and reconciles with the
  provider's fresh state on entry. Highlight visibility has no SavedVariables field.
- Positive border offset expands outward; negative offset insets. Visible
  thickness/inset are capped on small bars to preserve an interior without
  changing the stored choice or application duration.
- Tick height and travel use the bar's dimensions with the original one-unit
  inset. Border size, offset, and texture do not shorten or shift the markers;
  a texture's edge size is not its visible opaque thickness. Existing texture
  regions are resized when geometry changes and reused for live and preview ticks.
- Tick width adjusts marker bounds and travel consistently. Saved color is
  applied when a texture is first acquired and when appearance changes, including
  hidden pooled textures. Rendering reads validated width once per refresh and
  does not reapply color every animation frame. No tracked cast or timer changes.

## Feature-specific context matrix

Every required client check must record exact `GetBuildInfo()`, entry/sustained/
exit behavior, recovery, and inspected Lua errors, taint, blocked/forbidden
actions, and secret-value failures. Evidence-gated rows are mandatory live checks
that were not available during this implementation.

| Context or transition | Applicability | Expected behavior and practical proof |
| --- | --- | --- |
| Clean, schema 1/2/3, partially corrupt settings; repeated initialization and reset | Required | Off-client: preserve valid size/position/channels and false; add tick defaults; reset all supported choices; reject invalid edits. Actual persistence across sessions remains unverified |
| Guardian, Feral, Balance, Restoration, unspecialized Druid; non-Druid; enter/leave Bear | Evidence-gated | Off-client state cases exercise class-only eligibility, empty display, casting, and editing outside Bear. Actual form/spell availability requires each Druid spec in the client |
| Toggle while idle/active; first/overlapping casts; final expiry | Evidence-gated | Empty bar is visible by default, optional hide occurs after last expiry, ticks/count clear, and animation stops when idle. Source/stub assertions cannot prove actual timing/rendering |
| Spec, talent, loadout, spellbook changes; Cat retention acquired/lost | Evidence-gated | Refresh eligibility and known-spell-dependent retention, invalidate pending procs, retain assigned tick expiry where still applicable, recover without reload |
| Login, reload, relog, late activation, loading screen, zone/instance changes | Evidence-gated | Restore durable choices; discard stale estimates and track new casts; no fabricated preexisting applications |
| Death/resurrection | Evidence-gated | Clear old estimates and resume from observed casts; empty visibility still follows actual class/form state |
| Combat entry/sustained/exit, repeated changes, restricted encounters | Evidence-gated | Suspend editor and cancel owned unfinished color preview; preserve ordinary bar rendering; use only readable player casts; no taint, secret, or blocked-action failures |
| Solo/party/raid, open world, dungeon, raid, delve/scenario, battleground/arena | Evidence-gated | No content/group visibility gate; test relevant encounter restrictions and recovery through loading transitions |
| Vehicle, taxi, override/possess bar, pet battle, hidden UI, cinematic/movie/cutscene, quest dialogue/talking head | Evidence-gated | Follow actual form and UIParent visibility; end hidden editor interactions and recover without stale menus or previews |
| Blizzard Settings/Edit Mode overlap, dragging with panel open, native selection, Save/Revert/layout changes | Evidence-gated | Settings remain visible during bar dragging; native selection closes them; independent saved placement and existing snapping remain intact |
| Local eye, global Hide/Show all windows, repeated and mixed clicks; settings already open or reopened | Required | Off-client: latest action wins; only highlight opacity changes, sample and settings stay available, dragging remains usable, and the eye and tooltip reflect current state. Actual pixels and mouse interaction remain unverified |
| Provider absent, unsupported, late-loaded, eye initially hidden, late-created or replaced; repeated AddFrame and unrelated addon loads | Required | Off-client: local eye remains usable; supported late eye synchronizes; stale eye clicks do nothing, callbacks do not duplicate, and repeated discovery does not undo a local choice. Actual addon load ordering remains unverified |
| Hide highlight, native Hide/Show selections, combat entry/exit, Edit Mode exit/re-entry, reload | Evidence-gated | Native suspension ends editing; temporary hiding preserves its choice within the session and resets for a fresh session. Off-client native suspension and provider reset transitions pass; actual combat, reload, and UIParent transitions remain unverified |
| Eye tooltip enter/click/leave, panel closes, another tooltip owner; UI scale and frame recreation | Required | Off-client: label and sprite switch together, foreign tooltip survives, and Refresh cannot reopen a dismissed tooltip. Actual scale, sprite appearance, controller access, and frame recreation remain unverified |
| UI scale/resolution, minimum bar height, thick/inset/outset borders, late/replaced Edit Mode manager | Evidence-gated | Usable bounded settings and outline geometry; correct tick/count layering, reset clearance and module recovery; exact pixels require client rendering |
| Bar resize and border size/offset/texture changes while ticks already exist; preview to live and back; new and reused ticks | Required | Full inner-height markers retain their horizontal progress through border-only changes; all ticks follow bar resizing. Focused off-client regression covers these geometry transitions; actual textured borders, UI scaling, and live pixels remain unverified |
| Click each color swatch; tick color/opacity live preview, accept/cancel, reset, combat interruption, foreign picker owner | Required | Reuse existing picker transaction semantics for all three colors; update visible, hidden, and newly acquired ticks. Off-client checks exercise state and texture calls; actual swatch hit targets, border contrast, and native input remain unverified |
| Change tick width with slider/input, endpoints/invalid input, resize small/large bars, preview/live transition and overlapping/new ticks | Required | Keep validated width 1-20, full inner height, and every marker inside bar bounds; preserve configured width and color after repeated transitions. Off-client geometry and persistence checks; actual pixels/combat rendering remain unverified |
| Texture selectors closed/open, selecting/missing/late media, repeated menu opening, limited screen height | Required | Closed selector shows only the selected name; opened entries retain texture previews, late media recovery and scrolling. Off-client menu construction and selected-name checks; native rendering and low-resolution interaction remain unverified |
| Missing, delayed, restored or malformed data/media; event bursts | Required | Off-client: hide on secret eligibility, ignore unreadable casts, retain media names, restore late registration, and avoid stale callbacks. Corrupt installed texture files and actual secret events remain unverified |
| Picker accept/cancel/Escape/outside click, reset while picker open, editor/combat interruption, another picker owner | Required | Off-client transactions preserve accepted edits and restore canceled ones; close only owned controls; stale callbacks cannot change reset or hidden state. Native mouse/keyboard behavior remains unverified |
| Repeated editing, resizing, opening menus, registrations, long session | Evidence-gated | Reuse frames/hooks; no idle tracking animation, media scans in timer updates, duplicate callback work, or stale queued operations; long-session profiling remains unverified |
| Charges, cooldown availability/reset, target/focus/mouseover, pet units, equipment, roster role | Not applicable | None are inputs to the observed-cast timer, appearance, or visibility rules; no new source reads or event dependencies |

## Current verification and package

The final cosmetic follow-up reduces all swatches from 28 to 22 UI units, with
a 20-unit color square and the same one-unit border. Focused Lua parsing and
whitespace checks passed. The full-suite and package results below precede this
size-only adjustment; that archive still contains the earlier 28-unit swatches.
The existing swatch visual/hit-target checks remain unverified in game.

- `lua tests/runner.lua`: all 64 tests passed, loading the actual bundled
  libraries and add-on files in TOC order. The suite includes visibility-checkbox
  integration, current/legacy settings, color transactions, media recovery, border
  geometry, screen-height changes, lifecycle behavior, and existing snapping tests.
  Seven new tests cover local/global highlights, preview and drag preservation,
  tooltip ownership, late and replaced eyes, repeated discovery, and session reset.
  They caught and verified a fix for unrelated addon loading undoing a local choice.
  A tick regression reproduced a 24-unit bar shrinking its markers to 8 units
  with border size 8. It now verifies 22-unit markers, invariant horizontal
  positions across border changes, resizing, and preview/live texture reuse.
  The latest two tests cover schema 2-to-3 preservation and field-level recovery,
  plus tick width inputs, resizing, and new/pooled texture styling. Existing
  picker tests now also exercise tick accept/cancel/reset/combat interruption;
  menu tests retain popup previews and check selected names after media recovery.
- `luac -p`: all 16 runtime/library/test Lua files parse with the desktop runner.
- `git diff --check`: passed; Git reports its normal LF-to-CRLF notices.
- The optional `powershell -File tests/native_source_check.ps1` invocation was
  rejected by Windows PowerShell's script execution policy. No policy was changed.
  Its historical eight-source-scenario result below was not rerun for this change;
  the current main suite's snapping regressions did pass.
- Package inspection verifies the matching top-level folder/TOC, exact path casing
  for all TOC entries, all 11 runtime Lua files, both required adjacent license
  files, README and player changelog. The 16 archive entries match source SHA-256
  hashes. Tests, validation/provenance notes, Git, and repository instructions are
  excluded.
- Package: `C:\Temp\IronfurTracker-0.1.0-unreleased-tick-settings-20260903.zip`.
  SHA-256: `EA55843CD2FC0263B76E9C34EF15C3E9F09B43F6B7DA2A34216AE4C5D2026F10`.
- No package installation, game control, tags, commits, pushes, uploads or publishing
  were performed. The live context matrix and `GetBuildInfo()` remain unverified.

Result: Implemented, Unverified in game. No release-readiness claim is made
without the exact package being installed and the live matrix exercised.

---

# Previous snapping validation (historical)

The following records the earlier snapping change and its earlier artifact.
It is not validation of the current appearance/visibility package.

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
