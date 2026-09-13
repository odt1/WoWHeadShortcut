# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

WoWHeadShortcut, a World of Warcraft addon. Hover an item, spell or NPC and press Shift+Alt+C (or
run `/copylink`) to get a Wowhead URL for it. `/copylink options` opens the settings panel under
Interface > AddOns.

This folder is the live install at `C:\Games\WoW\Interface\AddOns\WoWHeadShortcut`, with its own git
repository. The folder name has to match the `.toc` name or the client won't load it. Lua and XML
edits take effect on `/reload`. Changes to the `.toc` (a new file, a new SavedVariables entry) and a
newly added `Bindings.xml` need a full client restart.

The addon used to be called CopyItemID. `LEGACY_BINDING_ACTION` in `WoWHeadShortcut.lua` is the only
place that name is still meant to appear.

## Target client

- WotLK 3.3.5a (`## Interface: 30300`), connected to an AzerothCore private server. Only use API that
  exists in 3.3.5. Retail and Classic-era docs describe functions this client doesn't have, or has
  with a different signature. For example, `PlaySound` here takes a sound name string, where retail
  takes a SoundKit ID.
- The client may be patched with AwesomeWotLK (`AwesomeWotlkLib.dll` in the game root), which adds
  the global `CopyToClipboard`. The stock client has no clipboard API. `ns:HasClipboard()` checks for
  the function on every copy and falls back to a StaticPopup with the URL selected when it's missing.
- NPC IDs come from the 3.3.5 hex GUID string (`0xF130` + 6 hex digits of creature entry + spawn
  counter), which is why the code reads `guid:sub(7, 12)`. Later clients use a different GUID format.
- `self.editBox` isn't reliably set on 3.3.5 StaticPopups. Look the box up as
  `_G[self:GetName() .. "WideEditBox"]` or `.. "EditBox"`, which is what Questie-335 and the popup
  here do.
- `UIDropDownMenuTemplate` and `OptionsCheckButtonTemplate` find their child regions by global name
  (`<name>Text`), so frames built from them need a name. `CheckButton:GetChecked()` returns `1` or
  `nil`, not a boolean.
- `Bindings.xml` has no working default key attribute for addons in this client. Key strings put
  modifiers in `ALT-CTRL-SHIFT-` order, as `WTF\Account\<name>\bindings-cache.wtf` shows.

Other 3.3.5 addons in `C:\Games\WoW\Interface\AddOns` are the best reference for what this client
supports. Grep them before relying on an API from memory.

## How it works

`WoWHeadShortcut.lua` holds the logic. It sets up the addon namespace (`local addonName, ns = ...`)
and exports it as the global `WoWHeadShortcut`, which is how `Bindings.xml` calls
`WoWHeadShortcut:CopyHovered()`. The `BINDING_HEADER_*` and `BINDING_NAME_*` strings for the Key
Bindings screen are defined there too.

`CopyHovered` checks `GameTooltip` in priority order: item link first, then spell, then unit. The
unit check skips players and falls back to `mouseover` when the tooltip has no unit. The URL is the
base URL, then the `TYPE_MAP` slug (`item=`, `spell=`, `npc=`), then the ID.

- `ns.sites` drives the site dropdown. An entry with a `url` is a preset; the entry without one uses
  `db.customUrl`. Nothing is inserted between base and slug, so a custom base has to end where the
  slug goes (`http://localhost/aowow/?` for AoWoW).
- `ns:PlayNamedSound` sends anything containing a slash, backslash or dot to `PlaySoundFile` and
  everything else to `PlaySound`. The copy sound only plays when the URL went to the clipboard.
- Settings live in the account-wide SavedVariable `WoWHeadShortcutDB`. On `ADDON_LOADED` any key
  missing from it is filled from `ns.defaults`, so a new setting only needs a default.
- The Shift+Alt+C default is set from code on `VARIABLES_LOADED`, the first point where bindings can
  be read. It runs once per account (`db.defaultBindingApplied`, kept out of `ns.defaults` so the
  options Defaults button doesn't re-arm it). It only takes the key when the key is free or still
  bound to the old CopyItemID action, and it prints a message instead when the key is taken.

`Options.lua` builds the Interface Options panel in `ns:InitOptions()`, called from the
`ADDON_LOADED` handler because `UIDropDownMenu_Initialize` runs the menu builder immediately and needs
`ns.db`. Widgets write to `db` as they change, so the panel's `okay` and `cancel` are no-ops. The
edit boxes' `OnTextChanged` handlers call `UpdateState`, which must never call `SetText` on an edit
box, or the handlers would loop.

## Checking changes

There is no build, lint or test setup. Outside the game you can only check syntax:

    luac -p WoWHeadShortcut.lua Options.lua

The `luac` on PATH is Lua 5.4, but the game embeds Lua 5.1. It accepts 5.4-only syntax such as
`goto`, `//`, the bitwise operators and `<const>`, all of which fail in game, so don't use them.

Runtime errors show up in game after `/reload`. `C:\Games\WoW\Logs\FrameXML.log` records load
problems.

## Style

Tabs for indentation. Chat output goes through `Print`, which adds the `|cff33ffcc[WoWHeadShortcut]|r`
prefix.
