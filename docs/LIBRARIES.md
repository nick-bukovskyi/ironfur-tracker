# Bundled libraries and artwork

Ironfur Tracker includes these libraries, so players do not need to install them
separately. Their licenses are retained alongside the source files and included
in the addon download.

| Library | Bundled version | License |
| --- | --- | --- |
| [LibStub](https://www.wowace.com/projects/libstub) | Minor 2, revision 76 | Public-domain dedication in the source |
| [CallbackHandler-1.0](https://www.wowace.com/projects/callbackhandler) | Minor 8, revision 26 | [BSD license](../libs/CallbackHandler-1.0/LICENSE.txt) |
| [LibSharedMedia-3.0](https://www.wowace.com/projects/libsharedmedia-3-0) | Minor 12000002, revision 176 | [LGPL 2.1](../libs/LibSharedMedia-3.0/LICENSE.txt) |

All three Lua files are copies from the author's
[LibSharedMedia-3.0 v12.1.0 distribution](https://www.wowace.com/projects/libsharedmedia-3-0/files/8691989),
reformatted with this repository's StyLua configuration.
LibStub and CallbackHandler load before LibSharedMedia, and all three load before
Ironfur Tracker's media settings.

LibSharedMedia makes registered fonts and textures available in the settings
menus. Additional media addons are optional.

The project's [MIT license](../LICENSE) covers Ironfur Tracker's original code
and documentation. Bundled libraries retain their own licenses. The logo is
based on World of Warcraft's Ironfur spell artwork; Blizzard artwork and
trademarks are not relicensed by this project. World of Warcraft is a trademark
of Blizzard Entertainment.
