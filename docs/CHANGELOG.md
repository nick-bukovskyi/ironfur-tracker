# Changelog

Changes to Ironfur Tracker, newest first. The development milestones below
record the work toward the first release; they were not separate public releases.

## [0.1.0] - Unreleased

### Added

- A time-based bar color mode: green with over half the duration left, yellow with a quarter to half left, and red with a quarter or less left.
- Color and opacity choices for each of the three time ranges.
- An Ironfur Tracker logo in the AddOns list.

### Changed

- Time-based colors now change at 50% and 25%, with clearer labels explaining each range.

### Fixed

- The settings window now starts vertically centered and fits the available screen height.
- The scrollbar now has its own space, so switching color modes keeps the settings aligned.
- Settings remain within the screen when resolution or UI scale changes.

### Known Issues

- Stacks already active when logging in, reloading the UI, or entering the world through a loading screen cannot be recovered. New casts are tracked immediately, but the display may temporarily show fewer stacks until the older applications expire.

---

## [0.1.0-dev.3] - Stack colors and text

### Added

- Druid class color and customizable stack-count color modes.
- Individual stack-color rules from 1 to 20, with skipped counts using the previous color.
- Stack text controls for font, size, color, alignment, horizontal and vertical position, and shadow or outline.
- Backdrop color and texture settings for the empty part of the bar.
- A Show ticks option to hide the markers while keeping the fill and stack count visible.

### Changed

- New setups use Druid orange, white text and ticks, a black border, and a dark backdrop.
- Settings are grouped into Visibility, Font, Bar, Backdrop, Border, and Tick.
- Font and texture choices now use recognizable names and preview their appearance.

### Fixed

- Adding and removing stack colors now acts on the count shown in the input.
- Removing a stack color automatically selects the range that takes its place.
- Opening Ironfur Tracker settings now closes a previously open EnhanceQoL settings window.

---

## [0.1.0-dev.2] - Appearance and Edit Mode

### Added

- Drag-to-position controls, a sample bar, and size settings in Blizzard Edit Mode.
- Snapping to the grid, screen guides, and nearby Edit Mode elements.
- Bar, tick, and border color controls, including opacity.
- Texture previews, border thickness and offset settings, and adjustable tick width.
- Account-wide saved settings and a Reset to Defaults button.
- An option to keep the empty bar visible in Bear Form, enabled by default.

### Changed

- The tracker now works for all Druid specializations while in Bear Form.
- Color swatches open the color picker directly, and texture previews appear inside the selectors.

### Fixed

- Tick markers now fill the bar's inner height with different border styles.
- EnhanceQoL's Hide all windows toggle now hides the tracker's Edit Mode highlight.
- The settings panel stays open while dragging the bar.

---

## [0.1.0-dev.1] - First tracker

### Added

- An Ironfur duration bar with a stack count and an independent moving tick for each cast.
- Automatic bar visibility in Bear Form.
- Duration adjustments for Ursoc's Endurance and Guardian of Elune.
- Continued tracking in Cat Form with Wildshape Mastery, with the bar hidden until returning to Bear Form.
