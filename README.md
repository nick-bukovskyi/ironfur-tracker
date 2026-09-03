# Ironfur Tracker

Ironfur Tracker is a focused World of Warcraft 12.1 addon for Guardian Druids.
It displays locally tracked Ironfur applications while the player is in Bear
Form.

Each successful Ironfur cast adds an independent tick at the right side of the
bar. The tick travels left as that application expires, the bar fill recedes
with the rightmost tick, and the centered number shows the locally tracked
stack count.

## Current behavior

- Targets WoW Retail 12.1.0 build 69587 (`Interface 120100`).
- Tracks only Guardian Druids (specialization ID 104).
- Shows the live bar only in Bear Form while at least one Ironfur application
  is tracked.
- Uses Ironfur's 7-second base duration.
- Supports Ursoc's Endurance (+2 seconds).
- Supports Guardian of Elune after Mangle (+3 seconds), including consumption
  by Frenzied Regeneration.
- Retains active applications in Cat Form with Wildshape Mastery while keeping
  the bar hidden. Returning to Bear Form shows the remaining time.
- Provides Edit Mode controls for moving the bar and changing its width and
  height.
- Saves bar size and position account-wide immediately.
- Has no addon slash commands or external libraries.

## Edit Mode

Open Blizzard Edit Mode while playing a Guardian Druid. The Ironfur Tracker
preview appears even when the player is not in Bear Form and no applications
are active.

- Drag the preview to move the bar.
- Click the preview to open its settings panel.
- Use either the slider or number field for bar width and height.
- Use **Reset to Defaults** to restore a 300 by 18 bar at screen center.

Width accepts whole numbers from 80 to 1000. Height accepts whole numbers from
8 to 128. These account-wide choices are owned by Ironfur Tracker and are not
part of Blizzard Edit Mode layout profiles, imports, exports, Save, or Revert.

## Install

Copy the `IronfurTracker` folder into:

`World of Warcraft\_retail_\Interface\AddOns\`

Then restart World of Warcraft or run `/reload` if the addon folder was already
present when the game launched.

## WoW 12.1 limitation

WoW 12.1 restricts aura applications, duration, and expiration data during
combat. Ironfur Tracker therefore uses successful player spellcasts as its
reliable source and predicts each independent expiry locally. If the UI is
reloaded while Ironfur is already active, those preexisting applications cannot
be reconstructed. New casts are tracked immediately, and the count becomes fully
accurate after any pre-reload applications have expired.

## Tests

From the addon directory, run:

```text
lua tests/runner.lua
```
