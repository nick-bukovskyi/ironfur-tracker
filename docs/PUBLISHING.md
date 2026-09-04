# Publishing Ironfur Tracker on CurseForge

## Create the project

Open [Create a project](https://authors.curseforge.com/#/projects/create/choose-game),
sign in, and choose **World of Warcraft > Addons**.

| Field | Value |
| --- | --- |
| Name | Ironfur Tracker, if available |
| Summary | A customizable Ironfur bar for Druids, with stack tracking, individual timers, and colors that follow stacks or time remaining |
| Primary category | Druid |
| Additional categories | Buffs & Debuffs, Tank |
| License | MIT License |
| Description | Copy the player-facing introduction, features, setup, and tracking limitation from [README.md](../README.md) |
| Avatar | [public/curseforge-icon.png](../public/curseforge-icon.png), 400 x 400 PNG |

Use the Images tab to upload the three files in
[public/screenshots](../public/screenshots): **Default appearance**, **WoW-style
appearance**, and **Settings**. The README's relative image links will not work
on CurseForge; use the uploaded gallery or insert its hosted image links instead.
Add the GitHub source link once the public repository exists.

CurseForge requires original, non-infringing avatar imagery. The prepared logo
is based on Blizzard's Ironfur artwork; permission to use that underlying
artwork as a project avatar has not been verified. Resolve that before submitting,
or use an original avatar that does not reuse Blizzard artwork.

Project creation, images, and descriptions follow the official
[creation guide](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project),
[submission tips](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips),
and [moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279).

## Build the download

From the repository root, in PowerShell:

```powershell
lua tests/runner.lua
./scripts/package.ps1
```

The build needs PowerShell 5.1 or newer and no external packaging tools. Lua is
only required for the separate test command. The script reads the version and
icon path from `IronfurTracker.toc`, checks the matching changelog heading, and
creates `dist/IronfurTracker-<version>.zip`. Rebuilding replaces that local ZIP
only after the new archive passes its file and content checks.

The ZIP contains one `IronfurTracker` folder, with `IronfurTracker.toc` directly
inside it. It includes the runtime code, game icon, changelog, project license,
and bundled library notices. Tests, screenshots, the repository README, scripts,
and local files are excluded. Do not upload a GitHub source ZIP.

## Check the actual download in WoW

The current target is **Retail 12.1.0**, build **69587**, interface **120100**.
The automated suite and package checks do not verify gameplay. Before calling
this a Release, install the exact ZIP and check:

- The addon loads, its AddOns-list icon appears, and no Lua errors are reported
- Bear Form visibility, casts, stack expiry, and duration-changing talents work
  before, during, and after combat
- All four color modes, font options, ticks, and backdrop behave as expected
- Edit Mode dragging, snapping, settings, EnhanceQoL interaction when installed,
  and small-screen or UI-scale changes remain usable
- Settings survive a reload; the documented reset of already-active timers is
  understood and new casts resume tracking

These in-game checks remain outstanding. Do not select Classic, PTR, or other
game versions without validating them first.

## Upload the first file

1. Open the project's **Files** tab and choose the file-upload action
2. Upload the ZIP from `dist`, using the same version in its display name
3. Select **Retail** and the validated **12.1.0** game version
4. Choose **Beta** while testing, or **Release** after the in-game checks pass
5. Paste only the current version's notes from [CHANGELOG.md](CHANGELOG.md),
   using Markdown formatting; the `dev` entries describe unpublished milestones
6. Check the publication timing before submitting: uploading the first file
   sends the project for moderation, and a file can become public after approval

For the approved addon to appear in the CurseForge app, it needs at least one
**Release** file, a game-version type, and a non-Experimental project status.
See the official [author requirements](https://support.curseforge.com/support/solutions/articles/9000196615).

No API key, automatic release workflow, or project ID is needed for this manual
upload. After the project is created, keep its URL and numeric ID for any future
automation. No placeholder IDs are included in this repository.

For future releases, update the TOC version and add matching player-facing notes
before building. Replace `Unreleased` with the actual publication date only when
the release is made. The prepared files do not create a CurseForge project,
publish a GitHub repository, or upload an addon automatically.
