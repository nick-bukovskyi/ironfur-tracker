# Ironfur Tracker

Ironfur Tracker is a focused World of Warcraft 12.1 addon for Druids.
It displays locally tracked Ironfur applications while the player is in Bear
Form.

Each successful Ironfur cast adds an independent tick at the right side of the
bar. The tick travels left as that application expires, the bar fill recedes
with the rightmost tick, and the centered number shows the locally tracked
stack count.

## Current behavior

- Targets WoW Retail 12.1.0 build 69587 (`Interface 120100`).
- Supports every Druid specialization, including Druids without a specialization.
- Shows the live bar in Bear Form, including an empty bar by default when no
  applications are tracked. Disable **Always show in Bear Form** to hide the bar
  after the final tracked application expires.
- Uses Ironfur's 7-second base duration.
- Supports Ursoc's Endurance (+2 seconds).
- Supports Guardian of Elune after Mangle (+3 seconds), including consumption
  by Frenzied Regeneration.
- Retains active applications in Cat Form with Wildshape Mastery while keeping
  the bar hidden. Returning to Bear Form shows the remaining time.
- Groups Edit Mode controls into Visibility, Font, Bar, Backdrop, Border and Tick.
- Snaps the dragged bar to Blizzard's grid, screen guides, and eligible visible
  Edit Mode elements when snapping is enabled.
- Saves size, position, appearance, and visibility account-wide immediately.
- Includes LibSharedMedia and its small dependencies; no separate addon is required.
- Has no addon slash commands.

## Edit Mode

Open Blizzard Edit Mode while playing any Druid. The Ironfur Tracker sample
appears even outside Bear Form, with a partially filled bar and three sample
ticks. These samples do not create tracked applications.

- Drag the preview to move the bar.
- Use Blizzard's **Enable Snap**, **Show Grid**, and **Grid Spacing** controls
  to choose snapping behavior. Alignment guides appear while dragging, and the
  bar snaps into place when released. Hiding the grid disables grid snapping
  without disabling snapping to eligible elements or screen guides.
- Click the preview to open its settings panel. Any open EnhanceQoL Edit Mode
  settings dialog closes when its public close control is available.
- Use the eye beside Close to hide or show the preview's selection highlight.
  The bar and settings remain visible, and the bar can still be dragged.
  EnhanceQoL's **Hide all windows** eye also controls this highlight when its
  supported Edit Mode library is present. A new Edit Mode session restores highlights.
- Use the Bar section's sliders or number fields for width and height.
- Click a bordered color swatch to choose bar, backdrop, tick, or border color with opacity.
  Changes preview immediately; canceling the picker restores the opening color.
- Open the bar, backdrop or border texture selector to see named visual previews.
  **Solid** uses Blizzard's built-in solid texture; other choices come from built-in shared media
  or enabled media-provider addons. Missing media temporarily uses Solid
  without erasing the saved selection.
- Use **Backdrop** to customize the color, opacity and texture underneath the
  fill. It shows through the unfilled part of the bar and remains visible when
  the bar is empty. New settings use black (#000000) at 80% opacity with Solid texture.
- Use the Tick section to set marker color and width from 1 to 20 with the slider
  or number field. Ticks keep their full inner height regardless of border styling.
- **Color mode** offers **Class color** (the default Blizzard Druid orange),
  **Solid** (a customizable deeper orange), and **By stack count**.
- In **By stack count**, choose a range or enter a **Stack count** from 1 to 20.
  The selector, number field and preview follow the same valid count. **Add** and
  **Remove** act on that visible count and keep it selected afterward. For an
  existing color, Remove and the swatch are enabled; for a missing color, Add is
  enabled and the preview shows its inherited color until you add it. Invalid or
  blank input stays visible and disables both actions without changing colors.
  Each color continues until the next configured count: keeping 1 and 3 makes
  2 inherit 1. Added colors copy the inherited color, and the highest range
  covers all higher counts. You can remove any rule, including 1 or the last one.
  Counts below the first rule, or an empty rule list, use your **Solid** color.
  Initial colors are red at 1, yellow at 2, green at 3, cyan at 4, and purple at 5+.
  Switching modes preserves your solid color and stack colors. The empty bar has
  no fill. Upgrades retain rules from 1 to 20 and discard rules above 20; an empty
  saved list stays empty. Reset restores the five initial colors.
- Adjust border size from 1 to 20 and offset from -20 to 20 with either a slider
  or number field. Positive offset expands outward; negative offset moves inward.
  These are UI units, like bar width and height. Very small bars limit the visible
  thickness and inset to keep an interior; the saved choice is retained.
- Use **Font** to show or hide the stack number, choose left/center/right placement,
  and adjust its horizontal offset. Positive offsets move right; negative offsets
  move left. Choose text color/opacity, a font family, size, and shadow/outline style.
  Font names preview their appearance inside the **Font** selector. New settings
  use white text, **Friz Quadrata TT**, size **14**, and **Drop shadow**. Unavailable fonts use
  Friz Quadrata TT, or the locale's native font if unavailable, until their provider
  returns. Hiding the number does not change stack colors.
- Use **Reset to Defaults** to restore a 300 by 18 bar at screen center, the
  class-colored fill, Solid textures, white ticks at width 2, black border at size 1,
  offset 0, and enabled empty-bar visibility. Text returns to white Friz Quadrata TT,
  size 14, Drop shadow, centered with no offset, and visible. The backdrop
  returns to black at 80% opacity with Solid texture. Existing custom choices survive upgrades;
  resetting applies all the new defaults together.
  Older texture selections named Default become Solid without changing their appearance.

Width accepts whole numbers from 80 to 1000. Height accepts whole numbers from
8 to 128. These account-wide choices are owned by Ironfur Tracker and are not
part of Blizzard Edit Mode layout profiles, imports, exports, Save, or Revert.
Color pickers and texture menus close when editing ends or combat starts.
The settings content scrolls when the available screen height requires it.
Text size accepts 8-64 UI units and horizontal offset accepts -500 to 500.

Snapping sets the bar's position; it does not attach the bar to another element.
Moving that element afterward leaves Ironfur Tracker where it was placed.
Blizzard elements do not snap toward Ironfur Tracker, and unrelated addon frames
are not added as snapping targets.

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
An empty bar and a count of **0** mean there are no locally tracked applications;
they do not prove that no preexisting Ironfur buff is active. Unreadable or
restricted event data is not used to create estimates.

This development build has automated test and build-matched source evidence.
In-game appearance, combat restrictions, and the gameplay matrix remain unverified.

## Tests

From the addon directory, run:

```text
lua tests/runner.lua
```
