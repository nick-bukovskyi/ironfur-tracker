# Bundled media libraries

Ironfur Tracker embeds the three runtime Lua files distributed in the official
[LibSharedMedia-3.0 v12.1.0 archive](https://www.wowace.com/projects/libsharedmedia-3-0/files/8691989).
They are unmodified. No Enhance QoL code, settings libraries, or media assets are
included.

Source archive: `LibSharedMedia-3.0-v12.1.0.zip`, downloaded September 3, 2026 from
[the author's CurseForge distribution](https://mediafilez.forgecdn.net/files/8691/989/LibSharedMedia-3.0-v12.1.0.zip).
Its MD5 matches the publisher's file record: `802ef2c8c7ee78aca74cddedc4ba6860`.

| Runtime file | Version | SHA-256 | License |
| --- | --- | --- | --- |
| `libs/LibStub/LibStub.lua` | Minor 2, revision 76 | `F93F7DFBD280C0F8E0328BB194FAA6DB541C3C50B3D4D37EB064C816F0EC5576` | Public-domain dedication retained in source |
| `libs/CallbackHandler-1.0/CallbackHandler-1.0.lua` | Minor 8, revision 26 | `84A15AF505E728AC5E5EB6A8EABA8989D1131D5F8BA14D11ABCFE4CE086DE3C1` | Ace3 BSD license in adjacent `LICENSE.txt` |
| `libs/LibSharedMedia-3.0/LibSharedMedia-3.0.lua` | Minor 12000002, revision 176 | `B2650FC5ACBFF310C7F7A23A36C8026A99D2441982D4B4F63AFB76489D56B214` | LGPL 2.1 as declared in source; full text in adjacent `LICENSE.txt` |

The CallbackHandler license comes from
[Ace3 commit bf6c018](https://github.com/WoWUIDev/Ace3/blob/bf6c018e13343640e6c10afebe42e1b894e6d649/LICENSE.txt).
The LGPL text comes from the
[Free Software Foundation](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt).
Keep these license files in player packages. LibStub and CallbackHandler load
before LibSharedMedia; all three load before `src/Media.lua`.

## Integration

Only `statusbar` and `border` media are offered. The add-on's `Default` option
always resolves to its original solid texture. Other selections store their
registered media name and resolve through the corresponding shared catalog.
An unavailable name falls back to solid without replacing the saved choice.
Registration callbacks refresh matching selected media when it becomes available.
Catalogs are rebuilt only when requested for settings, not during timer updates.

LibSharedMedia v12.1.0 validates new registrations using
`C_UIFileAsset.IsKnownFile`. The exact target's
[UIFileAsset API documentation](https://github.com/Gethe/wow-ui-source/blob/8ea15b61e45c0ed4eba01439c90757f86eb78d34/Interface/AddOns/Blizzard_APIDocumentationGenerated/UIFileAssetAPIDocumentation.lua)
defines this as a known-asset check; it does not guarantee a loose file can be
opened. Missing media registrations recover through the default texture, while
corrupt or unreadable installed media remain a client validation case.

Borders use the target build's public `BackdropTemplate` extension point and
`SetBackdrop`/`SetBackdropBorderColor`, shared by live bars and settings swatches.
See the pinned [Backdrop source](https://github.com/Gethe/wow-ui-source/blob/8ea15b61e45c0ed4eba01439c90757f86eb78d34/Interface/AddOns/Blizzard_SharedXML/Backdrop.lua)
and [template](https://github.com/Gethe/wow-ui-source/blob/8ea15b61e45c0ed4eba01439c90757f86eb78d34/Interface/AddOns/Blizzard_SharedXML/Backdrop.xml).
Appearance and geometry updates use only player settings and ordinary add-on
frame geometry, without passing game secrets into these APIs.

Border thickness and offset use UI units, matching width and height. Positive
offset expands the outline; negative offset moves it inward. At small sizes the
rendered inset and thickness are limited to preserve at least six UI units inside
the outline. The saved values remain unchanged and take full effect again when
the bar is large enough. Tick and text layers remain above the outline.

Exact-client rendering, media quality, UI scales, and combat/taint behavior still
require the gameplay validation recorded in `VALIDATION.md`.
