# Changelog

All notable changes to Ironfur Tracker will be documented in this file.

## [Unreleased]

### Fixed

- The settings panel now leaves the native bottom gap below Reset to Defaults.
- The settings panel now stays visible while dragging the bar in Edit Mode.

### Added

- Dragging the bar in Edit Mode now shows alignment guides and snaps to the
  grid, screen guides, and eligible visible elements using Blizzard's snapping
  controls. The bar stays in its placed position if another element moves later.
- The bar can now be moved while Blizzard Edit Mode is open.
- Edit Mode now offers linked slider and number controls for bar width and
  height.
- Bar size and position are now saved account-wide.
- A Reset to Defaults button restores the original size and centered position.

### Changed

- Edit Mode now uses a full-width Reset to Defaults button and more compact
  number fields.
- The live tracker now appears only while a Guardian Druid is in Bear Form.
- Cat Form with Wildshape Mastery now keeps active Ironfur applications hidden
  until Bear Form is restored.

## [0.1.0] - 2026-09-03

### Added

- Fixed centered Ironfur duration bar for Guardian Druids.
- Independent moving tick for every successful Ironfur cast.
- Centered active stack count and automatic visibility.
- Ursoc's Endurance and Guardian of Elune duration handling.
- Wildshape Mastery handling when Ironfur persists in Cat Form.
- Automated tests for gating, duration, stacking, expiry, and lifecycle events.
