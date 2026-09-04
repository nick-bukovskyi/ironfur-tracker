# Changelog

All notable changes to Ironfur Tracker will be documented in this file.

## [Unreleased]

### Fixed

- The settings window now fits its controls with matching left and right margins.
- Stack-color Add and Remove now act on the visible count, keeping the number
  field, selector and preview synchronized. Removing a color selects the range
  that inherits its count, such as 1-2 stacks after removing 2. Removing the first
  rule selects the next one; an empty list shows No stack colors.
- Selecting Ironfur Tracker now closes an open EnhanceQoL Edit Mode settings
  window instead of leaving the previous frame's controls alongside it.
- Tick markers now span the bar's inner height regardless of border size, offset,
  or texture.
- EnhanceQoL's Hide all windows toggle now also hides Ironfur Tracker's Edit Mode
  highlight.
- The settings panel now leaves the native bottom gap below Reset to Defaults.
- The settings panel now stays visible while dragging the bar in Edit Mode.

### Added

- Show ticks now controls marker visibility in the live bar and Edit Mode preview.
  It is enabled by default; hiding markers keeps the fill and stack count updating.
- The bar backdrop now has color, opacity and texture controls for the area
  underneath the fill.
- Stack text can now be hidden, aligned left/center/right, shifted horizontally or vertically,
  and customized with color, opacity, font family, size, and shadow/outline styles.
- Bar color can now use Blizzard's Druid class color or follow editable stack
  ranges. Add or remove individual starting counts; skipped counts inherit the
  previous color, and the highest range covers larger counts. Counts below the
  first rule or an empty rule list use the saved Solid color.
- Selecting a stack color previews that count on the bar; font selectors preview
  each available family.
- The settings panel now has an eye button to hide or show the bar's Edit Mode
  highlight while keeping its preview and settings available.
- Edit Mode settings now have Visibility, Font, Bar, Backdrop, Border and Tick sections.
- Bar, tick, and border colors can now be customized, including opacity.
- Tick width can now be changed with a slider or number input.
- Bar and border texture selectors now show previews of built-in and available
  shared-media textures.
- Border size and offset can now be changed with sliders or number inputs.
- The bar now stays visible with an empty fill and a count of zero in Bear Form
  by default. Turn off Always show in Bear Form to hide it between applications.
- Dragging the bar in Edit Mode now shows alignment guides and snaps to the
  grid, screen guides, and eligible visible elements using Blizzard's snapping
  controls. The bar stays in its placed position if another element moves later.
- The bar can now be moved while Blizzard Edit Mode is open.
- Edit Mode now offers linked slider and number controls for bar width and
  height.
- Bar size and position are now saved account-wide.
- Reset to Defaults restores the original size, centered position, appearance,
  and empty-bar visibility setting.

### Changed

- Font positioning now has Horizontal and Vertical controls. Existing horizontal
  offsets are preserved; Vertical starts at zero.
- New settings and Reset to Defaults use a black backdrop at 80% opacity, white
  stack text, and a black border. Existing custom colors are preserved.
- Texture selectors now use the explicit Solid name for Blizzard's built-in
  solid texture. Older Default selections become Solid; custom selections stay intact.
- Bar width and height controls now sit in the Bar section.
- Stack-color starting counts now range from 1 to 20. Any rule can be removed,
  including the first or last; upgrades retain in-range rules and discard rules
  above 20. Empty saved lists remain empty until colors are added or reset.
- Settings now put dimensions and placement before texture and color controls
  within each section.
- New settings use Druid class color, white ticks, and Friz Quadrata TT at size
  14 with Drop shadow. Font and text-style selectors use explicit names.
- Stack colors start red at 1, yellow at 2, green at 3, cyan at 4, and purple
  at 5 or more. Existing customized colors and sizes are preserved on upgrade.
- Click a compact bordered color swatch to pick a color.
- Texture previews now appear only inside the opened selectors.
- Edit Mode now uses a full-width Reset to Defaults button and more compact
  number fields.
- The live tracker now works for every Druid specialization while in Bear Form.
- All Druids can customize the tracker in Edit Mode, with sample ticks showing
  their selected appearance.
- Cat Form with Wildshape Mastery now keeps active Ironfur applications hidden
  until Bear Form is restored.

### Known Issues

- The counter reflects locally tracked casts. Reloading while Ironfur is active
  cannot restore applications cast before the reload; a zero count can appear
  until another cast is observed.

## [0.1.0] - 2026-09-03

### Added

- Fixed centered Ironfur duration bar for Guardian Druids.
- Independent moving tick for every successful Ironfur cast.
- Centered active stack count and automatic visibility.
- Ursoc's Endurance and Guardian of Elune duration handling.
- Wildshape Mastery handling when Ironfur persists in Cat Form.
- Automated tests for gating, duration, stacking, expiry, and lifecycle events.
