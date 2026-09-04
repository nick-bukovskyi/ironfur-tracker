# Changelog

All notable changes to Ironfur Tracker will be documented in this file.

## [Unreleased]

### Fixed

- Selecting Ironfur Tracker now closes an open EnhanceQoL Edit Mode settings
  window instead of leaving the previous frame's controls alongside it.

- Tick markers now span the bar's inner height regardless of border size, offset,
  or texture.
- EnhanceQoL's Hide all windows toggle now also hides Ironfur Tracker's Edit Mode
  highlight.
- The settings panel now leaves the native bottom gap below Reset to Defaults.
- The settings panel now stays visible while dragging the bar in Edit Mode.

### Added

- The settings panel now has an eye button to hide or show the bar's Edit Mode
  highlight while keeping its preview and settings available.
- Edit Mode settings now have Visibility, Size, Bar, Tick, and Border sections.
- Bar, tick, and border colors can now be customized, including opacity.
- Tick width can now be changed with a slider or number input.
- Bar and border texture selectors now show previews of default and available
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
