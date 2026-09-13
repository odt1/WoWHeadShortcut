# WoWHeadShortcut

A WotLK 3.3.5a micro-addon that copies the WoWHead link of the item, spell or NPC under your cursor with a shortcut (Shift+Alt+C by default).

When using [Awesome WotLK](https://github.com/noname08662/awesome_wotlk) the link goes straight to your clipboard, otherwise, with the vanilla client, the addon opens a small window with the link selected instead - copy it from there with Ctrl+C.

## Installation

1. Download `WoWHeadShortcut-<version>.zip` from the [latest release](../../releases/latest) and extract it into `World of Warcraft\Interface\AddOns`. The zip already contains the `WoWHeadShortcut` folder. Keep the folder name as it is, or the game won't load the addon.
2. Restart the game if it was running.
3. On the character select screen, click AddOns and check that WoWHeadShortcut is enabled.

## Usage

Hover over something and press Shift+Alt+C. That works on:

- anything that shows an item tooltip
- spells, in your spellbook or actionbars
- NPCs, whether you hover their tooltip or the creature itself in the world

You get a link like `https://www.wowhead.com/wotlk/item=19019`. With Awesome WotLK a short sound plays once it's on the clipboard. Without it a window pops up with the link highlighted; press Ctrl+C, then Enter or Escape to close it. If there's nothing the addon can link under your cursor, it tells you in chat.

Typing `/copylink` does the same as the key, which is handy in macros.

### Changing the key

Shift+Alt+C gets bound the first time you log in with the addon. If that key already does something else, the addon leaves it alone and says so in chat. To use a different key, open Game Menu > Key Bindings and scroll to the WoWHeadShortcut section. The addon won't overwrite a key you set there.

## Options

Game Menu > Interface > AddOns > WoWHeadShortcut or type `/copylink options`. Changes apply immediately and are shared by every character on your account.

| Setting | What it does |
| --- | --- |
| Link site | WoWHead (WotLK), or Custom to link to a site of your own. |
| Custom base URL | Used when Link site is Custom. The addon adds `item=123`, `spell=123` or `npc=123` to the end, so enter the address up to that point, for example `http://localhost/aowow/?` for a local AoWoW. The line below the box shows what a full link will look like. |
| Copy method | Shows whether Awesome WotLK was found, which decides if links go to the clipboard or open in a window. There's nothing to change here. |
| Play a sound after copying | Turns the sound on or off. It only plays when the link goes to the clipboard. |
| Sound | A game sound name such as `igMainMenuContinue`, or the path to a sound file. Click Test to hear it. |

## Commands

| Command | What it does |
| --- | --- |
| `/copylink` | Copies the link for whatever is under your cursor |
| `/copylink options` | Opens the options panel |

## License

MIT, see [LICENSE](LICENSE).
