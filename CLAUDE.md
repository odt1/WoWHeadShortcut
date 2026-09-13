# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A one-file World of Warcraft addon. Hover an item, spell or NPC, run `/copyitem`, and a Wowhead URL
for it lands on the system clipboard.

This folder is the live install at `C:\Games\WoW\Interface\AddOns\CopyItemID`. It has no git
repository and no history to fall back on. An edit takes effect the next time the game runs
`/reload`.

## Target client

- WotLK 3.3.5a (`## Interface: 30300`), connected to an AzerothCore private server. Only use API that
  exists in 3.3.5. Retail and Classic-era docs describe functions this client doesn't have, or has
  with a different signature. For example, `PlaySound` here takes a sound name string, where retail
  takes a SoundKit ID.
- The client is patched with AwesomeWotLK (`AwesomeWotlkLib.dll` in the game root). The stock client
  has no `CopyToClipboard`; that DLL adds it, and the call errors without the patch.
- NPC IDs come from the 3.3.5 hex GUID string (`0xF130` + 6 hex digits of creature entry + spawn
  counter), which is why the code reads `guid:sub(7, 12)`. Later clients use a different GUID format.

## How it works

`CopyItemID.lua` checks `GameTooltip` in priority order: item link first, then spell, then unit.
The unit check skips players and falls back to `mouseover` when the tooltip has no unit. The
resulting `(id, type)` goes through `TYPE_MAP` to build `WOWHEAD_BASE .. slug .. id`.

- `WOWHEAD_BASE` points at `wowhead.com/wotlk/`. The commented-out line underneath is a local AoWoW
  instance, which uses the same `item=`/`spell=`/`npc=` query slugs.
- The `COPY_HOVERED_ID` StaticPopup (an edit box with the URL selected) is still defined, but its
  `StaticPopup_Show` call is commented out and `CopyToClipboard` runs instead. Re-enabling the popup
  would let a client without AwesomeWotLK copy the URL by hand.
- The ODT account runs the command from a macro named `ItemID`, stored in
  `WTF\Account\ODT\macros-cache.txt`. Renaming `/copyitem` breaks that macro.
- The addon is disabled for the AzerothCore test and admin characters in their `AddOns.txt`.

A new Lua file has to be listed in `CopyItemID.toc` or the client never loads it.

## Checking changes

There is no build, lint or test setup. Outside the game you can only check syntax:

    luac -p CopyItemID.lua

The `luac` on PATH is Lua 5.4, but the game embeds Lua 5.1. It accepts 5.4-only syntax such as
`goto`, `//`, the bitwise operators and `<const>`, all of which fail in game, so don't use them.

Runtime errors show up in game after `/reload`. `C:\Games\WoW\Logs\FrameXML.log` records load
problems.

## Style

4-space indentation. Lines 72 and 73 of `CopyItemID.lua` use tabs; don't copy that. Chat output uses
the `|cff33ffcc[CopyID]|r` prefix.
