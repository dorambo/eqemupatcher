------------------------------------------------
TaipoUI v1.0.2
  __    __   __   __   __   __   __   __    __
 _\/_  _\/_ _\/_ _\/_ _\/_ _\/_ _\/_ _\/_  _\/_
 \/\/  \/\/ \/\/ \/\/ \/\/ \/\/ \/\/ \/\/  \/\/

------------------------------------------------

Purpose
- Offer a more clean, classic-reduced set of Rain of Fear 2 (RoF2) UI components.

Changelog
[0.1] - 2018-10-12
- First release for testing

- Main UI:
-- Removal of the Sony Marketplace button (just EQ button showing)

- Player Character Window
-- Addition of EXP gauge bar the the player character window

- Inventory:
-- Removal of all extra tabs except for the Inventory tab
-- Cleanup of non-classic stuff from the Inventory tab


[0.2] - 2018-10-13
- Player Character Window
-- Complete overhaul to emulate old DuxaUI style
-- HP and Mana regen mods are spell/buff/de-buff based mods, only (not server rate representative)
-- Please test and report any text cutoff/spacing issues


[0.3] - 2018-10-14
- Player Character Window
-- Fixed clipping of 4-digit health values in large HP text label

- Player Target Window
-- Removal of frilly/clutterring decorations

- Group Window
-- Removal of frilly/clutterring decorations


[0.4] - 2018-10-15
- Player Target, Group Windows
-- Added ability to resize

- Player Buffs Window
-- Made titleless for more compact view

- Spell Gems (Icons)
-- Added secondary UI folder for Duxa (Luclin-era) spell gem option


[0.5] - 2018-10-17
- Spell Gems (Icons)
-- Fix to Luclin era gems (which properly align to our LoN spell IDs)
-- Rounded and square options


[0.6] - 2018-10-20
- Hotbuttons
-- Integrated full inventory + gear set icons with large primary/secondary
-- Alternative icons now available under alternative\
-- To change out icons to Luclin square or rounded, copy/paste/replace all of the .tga files under square or rounded to your uifiles\TaipoUI\ folder


[0.7] - 2018-11-16
- Hotbuttons
-- Integrated full inventory now moved to alternative subfolder (not installed, by default)
-- To enable the integrated full inventory hotbuttons, copy/replace the inv-hotbutton\EQUI_HotButtonWnd.xml file into the main TaipoUI folder
- Pet Info
-- Cleaned up unused buttons
-- Changed default/initial size to allow more X axis room to show pet buffs


[0.8] - 2018-11-24
- Player Character Window
-- Addition of a compressed player window option in alternative subfolder (see screenshots)
-- To enable the compressed player window, copy/replace the compressed-playerwindow\EQUI_PlayerWindow.xml file into the main TaipoUI folder

- Inventory
-- Moved to cleaner window frame type (no decorations, see screenshots)


[1.0] - 2018-12-31
- Target Window
-- Implemented Target of Target (ToT) inside primary target window (blue HP bar)
-- Default width, height adjusted for new ToT pixels
-- Target window is adjustable and will need to be adjusted slightly for existing layouts to accomodate new height requirement

- Final/stable release; no major updates planned to this UI save bug fixes or new feature requests


[1.0.1] - 2019-01-03
- Inventory Window
-- Minor update to enable non-classic charm slot for server events & GMs that wish to use the slot.


[1.0.2] - 2019-01-05
- Target Window
-- Minor update to show ToT HP Percentage.