# MiniVS - A Vampire-Slayer port 

![Author](https://img.shields.io/badge/Author-rtxA-red) ![Version](https://img.shields.io/badge/Version-0.4-red) ![Last Update](https://img.shields.io/badge/Last%20Update-10/07/2020-red) [![Source Code](https://img.shields.io/badge/GitHub-Source%20Code-blueviolet)](https://github.com/rtxa/MiniVS)

## ☉ Description

MiniVS is a port of Vampire-Slayer as a mini-mod for Half-Life multiplayer. Players won't need to download anything outside of the game to play on your server.

## ☰ Commands

- **say !team** - *Show team menu.*
- **say !class** *Show class menu.*
- **sv_restart** - *Restart the game, both teams scores are reset.*
- **sv_restartround** - *Restart the round.*
- **mp_roundtime** \<value\> - *Round time in seconds. Default: 180.*

## ☰ Requirements
- **HLDS Build 8308** or newer.
- [Last AMXX 1.9](https://www.amxmodx.org/downloads-new.php)
- [HL Player Models API](https://forums.alliedmods.net/showthread.php?p=2673875#post2673875)
- [HL Weapon Mod 0.8](https://forums.alliedmods.net/showthread.php?t=183369)
- [HL Restore Map API](https://forums.alliedmods.net/showthread.php?p=2705090)

## ☉ Preview

[youtube]AHJ9sWNC2Uw[/youtube]

## ⤓ Download

- **Source** package contains the source code of the mod.
- **Full** package contains compiled plugins with Orpheu and WeaponMod ready to use.
- **Maps** package contains the map pack for MiniVS.

You will find the **Full** package along with the **Source** (maps package too) [here](https://github.com/rtxa/MiniVS/releases/).

## ⚙ Installation

1. Install everything required before you install MiniVS or nothing will work.
1. __Download__ the attached files and __extract__ them in valve folder.
2. __Compile__ all the files and save them in your plugins folder.

Now you are ready to play MiniVS.

## ⛏ To do

- ☐ Add CTC mode (Capture the Cross) and mode where slayers have to destroy all coffins.
- ☐ Add missing weapons for Molly and Eightball.
- ☐ Add missing powers for Louis and Nina.
- ☐ Add human decapitation.
- ☐ Add reload animations for third-person mode (Hack this by changing the animation extension).
- ☐ Add motorcycles.
- ☐ Improve bots support. RCBot works but slayers don't know how to kill vampires and vampires need to do high jump only when target is too high from them.

## ☆ Thanks to:

- KORD_12.7 for his HL Stocks and HL Weapon Mod.
- BIGs & X-RaY for the KSG-12 weapon.

## ☉ Notes

- The mod has **multi-language** support. You can translate the plugin into any language editing **minivs.txt** file found in lang's folder.
- Corpses limit has been raised to 8. Default is 4.
- This weapon mod version crashes with some maps. Using the latest one fixes the issue, but it doesn't work with latest HLDS build. 
- The maps in the mapcycle work out of the box. I do not guarantee anything with the others ones.

Please, feel free to create any issues or pull requests, any feedback will be appreciated.
