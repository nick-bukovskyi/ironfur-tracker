# Appearance, stack colors, fonts, and Druid visibility validation

## Current change and proof boundary

The current implementation adds grouped appearance settings, shared-media bar
and border selectors, and default empty-bar visibility for every Druid in Bear
Form. Settings remain account-wide. The latest addition makes the existing
full-size background beneath the fill configurable through Backdrop color,
opacity and texture controls. New/reset defaults are a black backdrop at 80%
alpha, white stack text, a black border, and explicit Solid textures in all three
texture menus. Saved custom colors and named media remain intact; old Default
texture names migrate to Solid.
The latest settings update fits the panel to the numeric controls with equal
20-unit side margins and adds Show ticks, enabled by default. Tick visibility
applies to the live bar and preview without changing tracking, fill or text.
Font placement now exposes Horizontal and Vertical offsets. The existing
horizontal setting stays intact; the new vertical setting starts at zero.
The follow-up adds a settings-panel eye and observes EnhanceQoL's global eye to
hide the selection highlight without hiding the bar sample, settings, or drag
target. Highlight visibility is temporary and is not saved.
The tick-height correction decouples markers from decorative border geometry.
The supplied screenshot shows short markers in the live bar, but does not
establish the client's exact build or saved border settings.
Clickable bordered swatches are 22 UI units with a 20-unit color square. Texture
previews appear only in opened menus. New settings and reset now use Blizzard's
Druid class color, white tick markers at width 2, and visible centered stack text
in Friz Quadrata TT at size 14 with Drop shadow. Existing valid choices survive
upgrades. Font and Text style menus expose concrete choices without a Default
entry; all texture menus also omit Default and offer a single built-in Solid.
Stack colors define editable starting thresholds with intentional gaps. The
latest fix synchronizes valid typed counts, the dropdown and the sample; Add
and Remove act on that visible count. Add retains the new count; Remove selects
the nearest remaining lower threshold, or the first remaining rule when no lower
rule exists. An empty list shows No stack colors and keeps a count ready for Add. Counts
are limited to 1-20, and the first or last rule can be removed. Below the first
rule or with no rules, stack mode uses the stored Solid color.
Opening Ironfur settings closes an open EnhanceQoL settings dialog through its
public close method, when available.
Sections now appear as Visibility, Font, Bar, Backdrop, Border and Tick; bar
width and height move into Bar and the separate Size section is removed.

- Target: Retail live 12.1.0.69587, repository-declared interface `120100`.
  Read-only inspection of
  `W:\Games\Battle.net\Apps\World of Warcraft\_retail_\Wow.exe` returns file
  version `12.1.0.69587` and product version `Version 12.1.0.69587`.
- Pinned source: Gethe/wow-ui-source `live`, commit
  [8ea15b61e45c0ed4eba01439c90757f86eb78d34](https://github.com/Gethe/wow-ui-source/tree/8ea15b61e45c0ed4eba01439c90757f86eb78d34),
  whose `version.txt` is `12.1.0.69587`.
- No live `GetBuildInfo()` capture, installation, client control, or real
  SavedVariables changes were performed. Source and stubs are not in-game proof.
- Version `0.1.0` and interface declaration are unchanged. Classic, PTR, and
  additional builds are outside this change's compatibility claim.
- The user-approved baseline commit `2adb672` passed all 64 tests and left a
  clean working tree before the font/stack-color change. The later 73-test run
  and font/stack-color archive predate the current defaults, sparse thresholds
  and dialog fix. The following 82-test run and settings-refinements archive also
  predate the count-control/schema 6 fix, which passed 83 tests and its archive
  checks. The schema 7 Backdrop addition passed 88 tests and archive checks.
  Schema 8 defaults passed 90 tests and the Solid-defaults archive checks.
  Schema 9 tick-visibility and panel-width changes passed 94 tests and archive
  checks. The removal-selection refinement kept schema 9 and passed 95 tests
  plus archive checks. Current schema 10 font-offset changes complete this series;
  all 96 tests and the updated archive checks passed.

## API and lifecycle evidence

All paths below are relative to the pinned source's `Interface/AddOns` directory.
The count-control fix changes existing validated settings and rendering inputs;
it adds no Blizzard API, event, template or client compatibility path.
The removal-selection refinement also changes only ordinary editor state and
labels, reusing the existing menu, number-input and picker refresh path. Saved
schema 9, palette inheritance, tracking and all API contracts remain unchanged.
The subsequent font-offset change adds a validated vertical input to the existing
text anchor call. It introduces no event, template or protected frame.
Backdrop reuses the existing texture, tint, anchoring, picker and menu contracts
on an ordinary addon-owned region; it introduces no protected frame or action.
The Solid rename retains the previously used `Interface\Buttons\WHITE8X8` asset
and those same API contracts. Bundled LibSharedMedia lists that asset as Solid
for background (line 79) and statusbar (line 197); the addon also offers it for
the border. The pinned UI source contains no WHITE8X8 call site, so catalog
evidence is secondary and actual asset rendering remains an in-game gate.

| Contract | Build-matched source | Design consequence |
| --- | --- | --- |
| Player class, cast event payload, secret predicates | `Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` and `SecretPredicatesDocumentation.lua` | Class token determines eligibility; no specialization query. Player cast payloads may still be restricted by individual spell flags, so secret values are ignored |
| Form IDs and existing form reader | `Blizzard_FrameXMLBase/Constants.lua`, Cat 1 and Bear 5 | Preserve the existing `GetShapeshiftFormID()` boundary; secret form values suspend rendering. Full legacy reader behavior across forms remains a live evidence gate |
| Known spells and spellbook changes | `Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua` | `C_SpellBook.IsSpellKnown` defaults to the player bank; `SPELLS_CHANGED` has no payload and refreshes retention/proc state |
| Druid class color | `Blizzard_APIDocumentationGenerated/ClassColorDocumentation.lua:11-24`; `Blizzard_SharedXMLBase/Color.lua:23-25,37-39` | Public `C_ClassColor.GetClassColor("DRUID")` may return nothing; otherwise it returns colorRGB with ColorMixin. Use `GetRGB()` and explicit alpha 1, because `GetRGBA()` does not supply a missing alpha. A missing class color falls back to the stored solid color. The constant token is ordinary non-secret input |
| Native color picker | `Blizzard_ColorPickerFrame/Mainline/ColorPickerFrame.lua` and its Mainline TOC | Direct RGBA alpha, live callbacks, cancel rollback, ownership through `extraInfo`; enabled game/mainline module is not load-on-demand |
| Show stacks and Font controls | `Blizzard_SharedXML/Shared/Button/CheckButtonTemplates.xml:50`, `Shared/InputBox/InputBoxTemplates.xml:70`, `Shared/Slider/MinimalSlider.xml:34`; `Blizzard_Menu/Mainline/MenuTemplates.xml:3` | Reuse `UICheckButtonTemplate`, `InputBoxTemplate`, `MinimalSliderWithSteppersTemplate` and `WowStyle1DropdownTemplate`. The offset uses an ordinary signed input validated on commit; font family and styles are native radio menus |
| Native font fallback | `Blizzard_Fonts_Shared/Shared/FontStyles.xml:172,196` and `Shared/Fonts.xml:597-648` | `GameFontHighlightLarge` inherits `GameFontNormalLarge`, then `SystemFont_Shadow_Large`, with localized font assets. Its font path remains the fallback when the preferred shared-media Friz Quadrata TT entry is unavailable. New/reset size is explicitly 14, not the native template's localized size |
| Stack-text font, position and tint | `Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua:121,500,560,675` | `GetFont` returns a nullable FontAsset, height and flags. `SetFont(asset,height,flags?)` requires a valid font asset/height and returns success. `SetJustifyH` takes horizontal justification; text color accepts RGB and optional alpha. Only validated settings and locally tracked counts enter this path |
| Horizontal and Vertical font offsets | `Blizzard_APIDocumentationGenerated/SimpleScriptRegionResizingAPIDocumentation.lua:135-148` | The existing five-argument SetPoint call accepts offsetX and offsetY in UI units. Both inputs remain validated ordinary numbers on the addon-owned FontString. Positive Y moves upward; negative Y moves downward. No source region, secure attribute or tracker state changes |
| Shadow and FontObject contracts | `Blizzard_APIDocumentationGenerated/SimpleFontAPIDocumentation.lua:199,264,277` and `SimpleFontStringAPIDocumentation.lua:529,620,633` | FontObject `SetFont` requires string path, height and flags and declares no return; FontString `SetFont` returns a boolean. Both expose shadow RGB/optional alpha and numeric X/Y offsets. FontString `SetFontObject` accepts a FontObject |
| Font preview objects | `Blizzard_SharedXML/FontableFrameMixin.lua:118-120,128-135`; `Blizzard_Menu/Compositor.lua:69,166-169` | Blizzard creates named FontObjects with `CreateFont`; no generated `CreateFont` entry exists in this pinned source. Compositor font strings prohibit `SetFont` but support `SetFontObject`. One hidden ordinary FontString checks font-load success; cached prefixed FontObjects receive the successful font and shadow for menu previews, with late-registration refresh |
| Clickable color swatches and tick tint | `Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua`, `SimpleTextureBaseAPIDocumentation.lua`, and `SimpleScriptRegionResizingAPIDocumentation.lua` | Existing `CreateTexture`, `SetColorTexture`, sizing and anchor contracts on ordinary addon-owned regions; no additional template or protected integration. A separate opaque gray border surrounds each clickable color texture |
| Backdrop texture, tint and layering | `Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua:600`, `SimpleRegionAPIDocumentation.lua:191`, `SimpleFrameAPIDocumentation.lua:131`; `Blizzard_SharedXML/UI.xsd` and `Backdrop.lua:266,412` | `SetTexture` accepts a nullable asset plus wrap/filter arguments and returns success; `SetVertexColor` accepts RGB and optional alpha. Both permit tainted secret arguments, but this feature passes validated ordinary settings. CreateTexture sets the BACKGROUND layer beneath the statusbar's default ARTWORK fill. Native Backdrop code pairs the same texture/tint calls. Reuse the region without changing fill, ticks or timers |
| Menus and pooled previews | `Blizzard_Menu/DropdownButton.lua`, `MenuTemplates.lua`, `Compositor.lua` | Native radio menus, scrollable lists, attached textures/templates, and per-dropdown closure |
| Scrollable settings | `Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua`, `MinimalScrollBar.lua`/XML | Native ScrollFrame/MinimalScrollBar synchronization; fixed reset-button clearance |
| Balanced settings width | `Blizzard_SharedXML/Shared/Scroll/MinimalScrollBar.xml:18,125,147`; `Shared/InputBox/InputBoxTemplates.xml`; `DialogTemplates.xml:97-103` | Numeric controls end at 363 UI units, giving a 403-wide panel with the existing 20-unit left margin mirrored on the right. Dividers/reset share that width; the stack Remove button anchors to the same right edge. Scrollbar center sits 10 units beyond content; its 8-unit track and 17-unit arrows fit the margin. The dialog background is inset 7 units, so arrow proximity to border artwork remains a live visual gate |
| Tick visibility | `Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua:1482` | Existing `SetShown(bool)` on the ordinary addon-owned tick layer controls inherited visibility, including newly acquired textures. The method is protected when the target frame is protected; this layer is not. No secure actions or new event/lifecycle paths are introduced; actual combat and taint behavior remains unverified |
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

Text styles are a finite add-on option list, not shared-media assets. The choices
are Drop shadow, None, Outline, Thick outline, Outline and shadow, and
Thick outline and shadow. Drop shadow is the new/reset default and uses black
alpha 1 at `(1,-1)`; combined outline/shadow uses alpha 0.6.
The installed EnhanceQoL `General/functions.lua:345-363` demonstrates those
combinations as a design reference. Its additional raster styles are outside
this change. LSM provides font families, not a standard shadow catalog. Generated
client docs identify `TBFFlags` without enumerating strings; pinned `UI.xsd`
supports none/normal/thick outlines. Actual glyphs, outlines, font loading,
opacity and menu appearance remain client-validation gates.
Font, shadow and justification setters accept secret arguments only when
untainted; this change supplies ordinary validated settings. FontString text
color also permits tainted secret arguments and can add color/alpha secret
aspects, but no secret text or color source is used here. Source contracts do not
prove combat, taint or restricted-encounter behavior.

### Optional EnhanceQoL integration

The installed source at
`W:\Games\Battle.net\Apps\World of Warcraft\_retail_\Interface\AddOns\EnhanceQoL\libs\EnhanceQoLEditMode\EnhanceQoLEditMode.lua`
declares
`EnhanceQoLEditMode-1.0` minor `21000001`. Its global eye changes native selection
alpha and writes `internal.managerEyeButton.allHidden` after applying its action
(lines 989-1069). It exposes no global-highlight callback. The narrow observer in
EditMode therefore accepts only that verified library minor and post-hooks the
eye's `OnClick`, reading the completed action's boolean. This observer does not
register Ironfur with EnhanceQoL or mutate its frames, layouts or eye state.

The public `RegisterCallback("enter", callback)` runs after the provider resets
its eye on entry (lines 4126-4135); a post-hook on public `AddFrame` discovers an
eye created later by `EnsureDialog` (lines 4289-4296). Repeated discovery retains a
local choice. A newly attached eye supplies initial state, and each subsequent
local or global click wins. Existing callbacks are reused and obsolete buttons
are ignored. Absent or unsupported library versions leave the local eye usable;
their global toggle integration is unsupported until its contract is reviewed.
No additional dependency is bundled.

The separate settings-dialog fix uses public `HideSettingsDialog(frame?)`
(lines 4353-4358), with no frame filter to close the active provider dialog. The
method returns false when no dialog is shown and true after hiding it. Its
`OnHide` resets provider selection indicators (lines 4159-4161). This fixes the
specific difference between EnhanceQoL's native `SelectSystem` observer (line
4193) and Ironfur's existing `ClearSelectedSystem` call. Provider deferred
settings refresh skips a hidden dialog (lines 4618-4623).

EditMode discovers the optional public method on each permitted selection and
calls it before opening Ironfur settings. This adds no hooks, timers, private
dialog access or provider registration, and does not call the provider while
Ironfur editing is suspended. Absence of the method leaves Ironfur usable. The
public capability check is separate from the exact-minor gate required by the
private eye observer. Actual overlapping mouse hits, provider picker cleanup,
deferred refresh and addon load ordering remain unverified in game.

The settings eye uses the installed library's demonstrated `LFG-Eye` texture
layout: 512 by 256, 64 by 64 frames, open frame 0 and closed frame 4. The native
texture methods are build-matched; actual asset rendering and hit targets still
require an in-game check. Highlight opacity is on an addon-owned ordinary frame,
with no protected attributes or native frame mutation. Exact combat and taint
behavior remain unverified.

## State and upgrade contract

- Config owns schema 10, defaults, validation, and durable choices. Additive
  validation preserves schema 1 size/position and schema 2 appearance, including
  fractional offsets and schema 3 tick settings. Tick width defaults to 2 in the
  range 1-20; tick color defaults to opaque white `(1, 1, 1, 1)`.
  Numeric fields and color channels are
  validated before the schema advances; existing valid choices are retained.
  Missing visibility and Show stacks default to true; explicit false is preserved.
- Schema 9 adds boolean `showTicks`, default true for missing/invalid fields and
  reset, preserving explicit false. Bar appearance applies it to the existing
  unprotected tick layer with `SetShown`; child textures keep current progress
  while hidden, so showing them again reveals the latest state. Tracker inputs,
  duration, count, fill and pooled texture ownership are unchanged.
- Schema 7 added `backdropColor` and `backdropTexture`. Schema 8 defaults to
  backdrop RGBA `(0, 0, 0, 0.8)`, border `(0, 0, 0, 1)`, and Solid for all three
  textures. Old Default aliases normalize to Solid before the schema advances;
  setters reject the obsolete alias. Existing valid color channels and other
  texture names are preserved; missing or invalid fields recover independently.
  Reset applies the new defaults. The existing BACKGROUND region stays anchored to
  the whole bar and visible under empty/partial fill; appearance changes do not
  rebuild it or change fill value, ticks or tracked application durations.
- Schema 10 retains `fontOffset` for Horizontal and adds `fontOffsetY` for Vertical.
  Both use integer UI units from -500 to 500, default/reset to 0, and normalize
  independently. Missing/invalid vertical values recover without replacing a
  valid saved horizontal offset; valid vertical settings survive initialization.
- Font defaults are Friz Quadrata TT, size 14, center position,
  both offsets 0 and Drop shadow. Size accepts 8-64 UI units.
  Text color defaults to white RGBA `(1, 1, 1, 1)`.
  Hide/show affects only the count text, not tick tracking, bar visibility or
  stack-dependent color. Appearance updates re-anchor and style the existing
  FontString without rebuilding it. Legacy family Default becomes Friz Quadrata
  TT; legacy style DEFAULT becomes Drop shadow. Other valid saved families,
  sizes and styles are retained. Neither font menu includes a Default entry.
- Class color is the default bar-color mode. It uses Blizzard's Druid RGB at
  alpha 1, with the saved solid RGBA as fallback if the API returns nothing.
  Switching among Class color, Solid and By stack count preserves stored colors.
- New/reset stack colors start at 1 red, 2 yellow, 3 green, 4 cyan and 5 purple.
  Each threshold applies through the count before the next threshold; the last
  applies to every higher count. Counts below the first threshold, or an empty
  rule list, use the stored Solid RGBA. The editor labels ranges and previews
  the current valid input count. There is no zero threshold: zero tracked stacks always
  leaves fill at 0, with solid tint in stack mode.
- Stack count accepts whole-number values from 1 to 20. A valid typed count updates
  the dropdown and preview; choosing a dropdown entry updates the input and
  preview. Add and Remove read this same visible count. Add retains it; Remove
  selects the newly covering range by choosing the nearest lower threshold.
  Without a lower threshold it selects the first remaining rule. With no rules
  it retains the editable count and labels the selector No stack colors. Input,
  swatch, preview and menu selection then follow the same surviving threshold.
  If a rule exists there, Add is disabled and Remove/the swatch are enabled. If
  it is missing, Add is enabled and Remove/the swatch are disabled; its preview
  still uses inherited color. Add copies that inherited color, including Solid
  below the first rule, into an independent entry. Remove accepts any existing
  rule, including 1 and the last rule. The inline hint explains inheritance and
  the Solid fallback.
- Blank, invalid, fractional or out-of-range input disables actions without
  mutating rules or replacing the draft. A canceled color edit cannot mutate a
  different count after input, dropdown, Add, Remove, reset or combat changes.
- Valid pre-schema-5 palettes are treated as dense: missing entries below their
  highest saved count recover from the saved solid color, preserving later
  choices within the new limit. Schema 5 and later gaps are intentional and
  remain gaps; no first rule is injected. Existing empty rule lists remain
  empty. New or reset lists receive the five initial colors. Schema 6 discards
  rules above 20 while retaining valid in-range choices. Invalid channels
  recover independently. Other valid settings are preserved; new defaults apply
  only to absent/invalid fields or explicit reset.
- Missing texture providers retain the selected name and use the built-in Solid.
  Missing font names retain the choice and resolve to Friz Quadrata TT when
  available, otherwise the native localized font. A failed font load retries
  that resolved fallback; late registration reapplies the saved selection.
- Core owns normalized Druid/form state and display decisions. Tracker remains
  the only owner of real application/proc timers. Static editor samples never
  enter Tracker and do not require an animation driver.
- Settings owns controls, menu cleanup and the current stack-count draft. While
  the panel is open in stack-color mode, its valid count chooses a synthetic
  bar/tick/count sample, including when no rule exists or text is hidden. This sample
  never enters Tracker or SavedVariables. With the panel closed, Edit Mode uses
  its normal three-stack sample.
- SettingsColorPicker owns native color-picker transactions for the solid,
  backdrop, tick, border, text and indexed stack colors. It validates through Config, applies
  previews through the Settings callback, rolls back canceled edits, and ignores
  stale or foreign-owner callbacks. Settings cancels owned previews before mode,
  index, palette, reset or editing-lifecycle changes. EditMode owns selection,
  dragging, and Blizzard hooks; native layout storage is untouched.
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
| Clean, schema 1/2/3/4/5/6/7/8/9/10, partially corrupt settings; repeated initialization and reset | Required | Preserve existing choices, including explicit false, sparse rules, empty lists, custom colors, media and horizontal text placement. Repair only invalid fields; migrate Default texture aliases to Solid and add vertical placement at zero. Reset restores both text offsets to zero and the other current defaults. Schema 10 defaults, preservation and corrupt-field repair passed off-client. Actual persistence across sessions remains unverified |
| Show ticks on/off in Edit Mode and live tracking; casts and expiry while hidden; reset, hidden text and empty fill | Required | Hide the tick layer only; continue fill, count and stack colors, including new/expired ticks. Restore current markers without reviving expired ones or duplicating regions. Persist false and reset true. Focused off-client regressions passed; live preview/rendering, combat interruption and reload persistence remain unverified |
| Balanced width in all color modes, full-height and scrolling panels, repeated open/close and reset | Required | Preserve the existing 20-unit left margin and match the numeric input's right margin; fit stack actions and hint text within the same width. Keep scrollbar usable and reset reachable. Off-client geometry assertions passed; actual font wrapping, UI scale, native scrollbar border clearance and pointer interaction remain unverified |
| Guardian, Feral, Balance, Restoration, unspecialized Druid; non-Druid; enter/leave Bear | Evidence-gated | Off-client state cases exercise class-only eligibility, empty display, casting, and editing outside Bear. Actual form/spell availability requires each Druid spec in the client |
| Toggle while idle/active; first/overlapping casts; final expiry | Evidence-gated | Empty bar is visible by default, optional hide occurs after last expiry, ticks/count clear, and animation stops when idle. Source/stub assertions cannot prove actual timing/rendering |
| Spec, talent, loadout, spellbook changes; Cat retention acquired/lost | Evidence-gated | Refresh eligibility and known-spell-dependent retention, invalidate pending procs, retain assigned tick expiry where still applicable, recover without reload |
| Login, reload, relog, late activation, loading screen, zone/instance changes | Evidence-gated | Restore durable choices; discard stale estimates and track new casts; no fabricated preexisting applications |
| Death/resurrection | Evidence-gated | Clear old estimates and resume from observed casts; empty visibility still follows actual class/form state |
| Combat entry/sustained/exit, repeated changes, restricted encounters | Evidence-gated | Suspend editor and cancel owned unfinished color preview; preserve ordinary bar rendering; use only readable player casts; no taint, secret, or blocked-action failures |
| Solo/party/raid, open world, dungeon, raid, delve/scenario, battleground/arena | Evidence-gated | No content/group visibility gate; test relevant encounter restrictions and recovery through loading transitions |
| Vehicle, taxi, override/possess bar, pet battle, hidden UI, cinematic/movie/cutscene, quest dialogue/talking head | Evidence-gated | Follow actual form and UIParent visibility; end hidden editor interactions and recover without stale menus or previews |
| Blizzard Settings/Edit Mode overlap, dragging with panel open, native selection, Save/Revert/layout changes | Evidence-gated | Settings remain visible during bar dragging; native selection closes them; independent saved placement and existing snapping remain intact |
| EnhanceQoL dialog open; click Ironfur repeatedly; switch back; hidden highlight and drag | Required | Close provider dialog through its public method before showing Ironfur, clear the provider's selection through its own cleanup, preserve Ironfur preview/drag and temporary highlight choice. Four focused regressions pass with the seven prior highlight tests; removing the close call in memory makes all four new regressions fail. Actual overlapping mouse input, dialog pixels, provider picker/deferred cleanup and native behavior remain unverified |
| Optional provider close API absent or becomes available; combat suspends editing then ends | Required | Ironfur remains usable without the method, discovers it on the next selection, avoids provider calls during suspension, and recovers afterward. Focused off-client capability/combat scenarios passed; actual provider loading, recreation, lockdown and taint remain unverified |
| Local eye, global Hide/Show all windows, repeated and mixed clicks; settings already open or reopened | Required | Off-client: latest action wins; only highlight opacity changes, sample and settings stay available, dragging remains usable, and the eye and tooltip reflect current state. Actual pixels and mouse interaction remain unverified |
| Provider absent, unsupported, late-loaded, eye initially hidden, late-created or replaced; repeated AddFrame and unrelated addon loads | Required | Off-client: local eye remains usable; supported late eye synchronizes; stale eye clicks do nothing, callbacks do not duplicate, and repeated discovery does not undo a local choice. Actual addon load ordering remains unverified |
| Hide highlight, native Hide/Show selections, combat entry/exit, Edit Mode exit/re-entry, reload | Evidence-gated | Native suspension ends editing; temporary hiding preserves its choice within the session and resets for a fresh session. Off-client native suspension and provider reset transitions pass; actual combat, reload, and UIParent transitions remain unverified |
| Eye tooltip enter/click/leave, panel closes, another tooltip owner; UI scale and frame recreation | Required | Off-client: label and sprite switch together, foreign tooltip survives, and Refresh cannot reopen a dismissed tooltip. Actual scale, sprite appearance, controller access, and frame recreation remain unverified |
| UI scale/resolution, minimum bar height, thick/inset/outset borders, late/replaced Edit Mode manager | Evidence-gated | Usable bounded settings and outline geometry; correct tick/count layering, reset clearance and module recovery; exact pixels require client rendering |
| Bar resize and border size/offset/texture changes while ticks already exist; preview to live and back; new and reused ticks | Required | Full inner-height markers retain their horizontal progress through border-only changes; all ticks follow bar resizing. Focused off-client regression covers these geometry transitions; actual textured borders, UI scaling, and live pixels remain unverified |
| Click each color swatch; color/opacity live preview, accept/cancel, reset, combat interruption, foreign picker owner | Required | Shared picker ownership covers solid, tick, border, text and selected stack colors; update visible, hidden, and newly acquired regions. Input/dropdown/removal transactions and stale-callback regressions passed off-client. Actual 22-unit hit targets, border contrast and native input remain unverified |
| Change tick width with slider/input, endpoints/invalid input, resize small/large bars, preview/live transition and overlapping/new ticks | Required | Keep validated width 1-20, full inner height, and every marker inside bar bounds; preserve configured width and color after repeated transitions. Off-client geometry and persistence checks; actual pixels/combat rendering remain unverified |
| Texture selectors closed/open, selecting/missing/late media, repeated menu opening, limited screen height | Required | Closed selector shows only the selected name; opened entries retain texture previews, late media recovery and scrolling. Off-client menu construction and selected-name checks; native rendering and low-resolution interaction remain unverified |
| Backdrop color/texture during empty, partly filled, active and expired bars; resizing and repeated refresh | Required | Reuse the full-size BACKGROUND region, reveal it below the unfilled area, apply black at 80% alpha and Solid for fresh/reset settings, and leave fill progress, tick geometry and tracked timers unchanged. Focused appearance assertions passed with new defaults; actual draw order, alpha blending, texture pixels and gameplay transitions unverified |
| Backdrop RGBA picker preview, accept/cancel, reset, combat interruption and stale callbacks | Required | Use the shared owned transaction, roll back canceled changes, restore default RGBA on reset, and prevent callbacks after editing ends from changing the backdrop. Picker transactions passed off-client; native picker and combat/taint behavior unverified |
| Missing or late backdrop media; shared provider also supplies selected fill; repeated menu opening | Required | Use the existing statusbar catalog and popup previews; retain missing saved name, use Solid, and reapply when registered. Refresh both selected consumers when appropriate without changing their independent saved colors/textures. Late-media recovery tests passed with new defaults; actual provider load order and asset rendering unverified |
| Bar, backdrop and border menus with built-in or late media named Solid/Default | Required | Offer exactly one built-in Solid choice and no Default; reserve Solid against provider replacement for textures only. Font families named Solid remain usable. Menu and resolution regressions passed off-client; native popup preview pixels remain unverified |
| Reordered sections and removed Size section; short screen, scrollbar, width/height and reset access | Required | Order Visibility, Font, Bar, Backdrop, Border, Tick; place width/height in Bar, retain exactly one set of controls, scrolling and bottom reset clearance. Section order and width/height placement assertions passed off-client; actual scale, resolution and native input unverified |
| Class/Solid/By stack count switches; available/missing class RGB; reset and prior custom choices | Required | New/reset Class color uses Druid RGB with explicit alpha 1; missing API result uses stored solid RGBA. Mode changes preserve solid and threshold choices. Off-client class-color, fallback, mode-preservation and reset tests passed; actual class-color rendering and client API behavior unverified |
| Stack mode with zero, boundaries, gaps, counts above 20, missing first rule and empty rules | Required | Inherit the greatest threshold at or below the count, use Solid below the first or with no rules, and keep the final rule active above 20. Zero has no fill; hiding text does not change color. Lookup and empty-rule tests passed off-client; actual gameplay rendering unverified |
| Type count versus select dropdown; existing/missing counts; Add/Remove exact visible count | Required | Valid counts synchronize both controls and preview. Existing rule: Add disabled, Remove/swatch enabled. Missing typed rule: Add enabled, Remove/swatch disabled, inherited-color preview. Add selects its new rule; Remove selects the nearest lower surviving threshold, or first remaining rule. No remaining rules shows No stack colors and enables Add. Removal-selection and picker-target regressions passed off-client; native input, selected radio, labels and color-picker targeting remain unverified |
| Remove count 1, remove final rule, add afterward, input 20 versus 21, blank/invalid drafts | Required | First and last rules may be removed; no rules uses Solid. Only integer 1-20 edits are valid. Invalid drafts remain visible, disable actions and do not mutate settings. Control and boundary tests passed off-client; actual keyboard/focus behavior unverified |
| Picker open then typed/dropdown count change, removal, reset, or combat suspension | Required | Cancel the old color transaction before switching the active count or deleting its rule; stale callbacks cannot recreate a deleted rule or recolor a different one. Reset seeds five rules, combat exits editing cleanly. Regressions passed off-client; actual picker/lockdown behavior unverified |
| Show stacks toggle while empty, live or preview; left/center/right; signed Horizontal/Vertical offsets and font-size endpoints | Required | Text visibility defaults on; anchors and justification follow the selected position with independent X/Y offsets, preserve count while hidden, and refresh on re-enable. Both offsets default to 0, preserve saved values independently, and reset together. Signed inputs/sliders and schema 9-to-10 migration passed focused regressions. Live pixels, large glyphs, UI scale, clipping, scrolling, combat transitions and persistence across sessions remain unverified |
| Friz/native fallback and shared font families; missing/failed/late fonts; repeated menus | Required | Show concrete font names without Default, default/reset to Friz size 14, retain missing names, and resolve fallback without overwriting the choice. A hidden FontString checks loading; compositor text receives reusable FontObjects. Off-client fallback, compositor, concrete-default migration and menu tests passed. Actual assets, alphabets, fallback rendering and pooled-menu behavior unverified |
| Drop shadow/None/outline combinations and text RGBA; switches, upgrades and reset | Required | No Default style menu entry; new/reset and legacy DEFAULT use Drop shadow. None clears prior shadow, combined styles apply fixed alpha/offset, and valid saved styles survive. Text color remains independent from fill. Off-client style, color transaction and reset tests passed; actual raster/outline/shadow pixels unverified |
| Missing, delayed, restored or malformed data/media; event bursts | Required | Off-client: hide on secret eligibility, ignore unreadable casts, retain media names, restore late registration, and avoid stale callbacks. Corrupt installed texture files and actual secret events remain unverified |
| Picker accept/cancel/Escape/outside click, reset while picker open, editor/combat interruption, another picker owner | Required | Off-client transactions preserve accepted edits and restore canceled ones; close only owned controls; stale callbacks cannot change reset or hidden state. Native mouse/keyboard behavior remains unverified |
| Repeated editing, resizing, opening menus, registrations, long session | Evidence-gated | Reuse frames/hooks; no idle tracking animation, media scans in timer updates, duplicate callback work, or stale queued operations; long-session profiling remains unverified |
| Charges, cooldown availability/reset, target/focus/mouseover, pet units, equipment, roster role | Not applicable | None are inputs to the observed-cast timer, appearance, or visibility rules; no new source reads or event dependencies |

## Current verification and package

Baseline commit `2adb672` was user-approved and verified with 64 passing tests
and a clean working tree. A subsequent 73-test run, 18-file Lua parse and
17-entry archive verified the earlier schema 4 font/dense-palette implementation.
The next schema 5 revision passed 82 tests, parsed all 19 Lua files and verified
its 17-entry settings-refinements archive. The schema 6 count-control fix then
passed 83 tests, parsed 19 Lua files and verified its 17-entry stack-controls
archive. These results predate the later customization changes and remain historical evidence.

- Previous `lua tests/runner.lua`: all 83 tests passed. The count-control regressions
  cover typing 6 while another count was selected, removing only 6, keeping
  input unchanged after Add/Remove, dropdown synchronization, disabled invalid
  drafts, picker rollback before a typed change, removal of 1 and the final
  rule, empty-palette persistence, and the 20/21 boundary. Existing font, class
  color, appearance, tracker and Edit Mode regressions continue to pass.
- Focused dialog/highlight run: all 11 tests passed. All four new dialog
  regressions fail with the close call removed in memory; the seven existing
  highlight tests still pass. This does not prove native mouse or combat behavior.
- Current `lua tests/runner.lua`: all 96 tests passed, including five Backdrop
  regressions covering defaults/migration, independent empty/live/expired
  rendering, RGBA rollback/reset/combat callbacks, late media recovery, and
  section order with width/height in Bar. Two additional regressions cover schema 8
  alias migration without overwriting custom colors/media, and exactly one
  reserved Solid option in each texture menu with font families unaffected.
  Four regressions cover Show ticks persistence/validation, hidden pooled
  and newly created preview markers/reset, live timing/colors/expiry/restoration,
  and balanced input margins across color modes and a short scrolling viewport.
  The latest removal regression confirms 2 selects the 1-2 range, exactly one
  matching radio is selected, the picker edits rule 1 without altering other
  colors, and removing the first rule selects the next one. Existing tests also
  verify highest-rule removal, No stack colors when empty, and adding again.
  The vertical-offset regression confirms schema 9-to-10 initialization preserves
  horizontal placement, repairs only invalid vertical input, retains valid vertical
  values and clamps persisted values to -500/500. Existing control/reset tests now
  exercise both axes and exact Horizontal/Vertical labels at all three anchors.
  All 21 Lua files parsed successfully;
  `git diff --check` passed.
- The current TOC still contains 12 runtime/library Lua files and loads
  `SettingsColorPicker.lua` before `Settings.lua`. The inspected workspace now
  contains 21 runtime/library/test Lua files.
- Current no-upload archive: all 17 entries have exact path casing and matching
  workspace source hashes. The package includes 12 runtime/library Lua files,
  matching folder/TOC, README, changelog and library licenses. Tests and
  development notes are excluded.
- Archive: `C:\Temp\IronfurTracker-0.1.0-unreleased-font-offsets-20260903.zip`
  SHA-256: `D361B9A836CBB71FF70F32C0B0DCECF03587F4A05C518C94ACE90923C4D29C68`
- Previous stack-range-selection archive (historical): `C:\Temp\IronfurTracker-0.1.0-unreleased-stack-range-selection-20260903.zip`
  SHA-256: `7CC7E37FE2AB7B8D5843B0DE844B878F522C73B30FFA2DC8212892A9F0895C53`
- Previous tick-visibility archive (historical): `C:\Temp\IronfurTracker-0.1.0-unreleased-tick-visibility-20260903.zip`
  SHA-256: `2499A98F35311127F4BE7B26BEA80A8A5F35D12D494032A9FACB21467D0B9E2D`
- Previous Solid-defaults archive (historical): `C:\Temp\IronfurTracker-0.1.0-unreleased-solid-defaults-20260903.zip`
  SHA-256: `41B2618B6D775EFA00512B9D30C7CABAF581A8CB9B072DFA80020E34F90F2C46`
- Previous Backdrop archive (historical): `C:\Temp\IronfurTracker-0.1.0-unreleased-backdrop-20260903.zip`
  SHA-256: `14B51FE6EAFF17D73ACF30CBC4FB7A3DF08167376AB66E60DF9FCDD1B6BAA10E`
- Previous archive (historical): `C:\Temp\IronfurTracker-0.1.0-unreleased-stack-controls-20260903.zip`
  SHA-256: `8FA8FE59AB0A411622D9E737079B097484810577D2F473E36DFD2BCFC4FC4391`
- Previous settings-refinements archive (historical):
  `C:\Temp\IronfurTracker-0.1.0-unreleased-settings-refinements-20260903.zip`.
  SHA-256:
  `B0B3E43A1C31F0F1AFAFB9D47DBD593A3E099D6A05EF3396BE14CE89AD707C14`.
- Previous font/dense-palette archive (historical):
  `C:\Temp\IronfurTracker-0.1.0-unreleased-font-stack-colors-20260903.zip`.
  SHA-256:
  `0E334BC7C7FDB94BB2493240B59F94C0B8DD01B4E8954467FD0237A40ADD03F4`.
- The prior tick-settings artifact
  `C:\Temp\IronfurTracker-0.1.0-unreleased-tick-settings-20260903.zip`, SHA-256
  `EA55843CD2FC0263B76E9C34EF15C3E9F09B43F6B7DA2A34216AE4C5D2026F10`,
  is historical. It predates the final swatch-size adjustment and this feature
  and is not the current delivery artifact.
- The optional native-source snapping script previously encountered Windows
  PowerShell execution policy; no policy was changed. Its historical results
  below remain distinct from the current main-suite and feature results.
- No live `GetBuildInfo()` capture, package installation, client control or real
  SavedVariables changes were performed. No tags, pushes, uploads or publishing
  were performed. The implementation is organized into seven focused commits:
  EnhanceQoL dialog handoff, font and stack-color controls, backdrop settings,
  appearance defaults, tick visibility and margins, range selection, and font offsets.
  Each complete commit snapshot passed its matching suite: 68, 83, 88, 90, 94,
  95 and 96 tests respectively. Intermediate snapshots were checked in temporary
  directories without replacing the final working files.
  A separate documentation commit consolidates the current API, package and
  gameplay-validation evidence without changing runtime behavior.

Result: Horizontal and Vertical font-offset implementation, automated and package checks passed.
The live context matrix remains unverified. A
reviewed diff and off-client checks do not establish release readiness; the
exact artifact must be installed and the live matrix exercised.

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
