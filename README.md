# ZStats T7

**Live Zombies stats and a match recap for Black Ops III**

by Xep

[**Subscribe on Steam Workshop**](https://steamcommunity.com/sharedfiles/filedetails/?id=3814909842) or download the linked T7 mod from this repository's GitHub Releases.

[![Support the mod on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/F6L1285ROA)
[![Support the mod on Patreon](https://img.shields.io/badge/Patreon-Xeptix-F96854?logo=patreon&logoColor=white)](https://www.patreon.com/Xeptix)
[![Join the Discord](https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white)](https://discord.gg/RE85HRwYZZ)

ZStats adds a compact live HUD, a round-MVP callout, and a Game Over recap without
replacing the stock scoreboard. It tracks the match while you play and gives solo
players a personal summary or co-op players team awards and their own summary at
the end.

- **See the useful numbers now:** match time, zombies left, points per round
  (PPR), and kills per round (KPR) are on the default HUD.
- **Make the HUD yours:** choose Minimal, Compact, Detailed, or Custom; move and
  scale it, change the background, and show only the rows you want.
- **Keep personal bests:** career records belong to each client and mark new
  bests in orange. Match Only is there when you want a clean slate each game.
- **Read a real match recap:** earned, spent, and ending points are separate;
  the stock scoreboard remains in place.

This is the Black Ops III port of [ZStats](https://github.com/Xeptix/ZStats).
Both ports use the same public version and setting names.

---

## Requirements

Black Ops III Zombies and either the Workshop, the direct-download mod, or a
supported script loader. ZStats is designed for
ordinary round-based Zombies. Dead Ops Arcade and Nightmares are outside its
Zombies-script integration.

Black Ops III enables one selectable mod at a time. Use the combined
[ZBundle](https://steamcommunity.com/sharedfiles/filedetails/?id=3802815997)
when you want ZStats alongside the other Z mods. The T7 downloads have distinct
purposes: the **ZStats T7** ZIP is the linked mod for players;
the **ZStats T7 Script** ZIP is for supported script loaders;
the **ZStats T7 Workshop** ZIP is BO3 Mod Tools source.
The Workshop source ZIP is not a drop-in game mod.

---

## Install

Subscribe to [ZStats on Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3814909842), select `zstats` in
Black Ops III's **Mods** menu, and start a new Zombies match. The Workshop
handles updates. To use the combined mod, subscribe to ZBundle and select it
instead of the standalone ZStats item.

For a direct GitHub install, download the **ZStats T7** player ZIP from
[Releases](https://github.com/Xeptix/ZStatsT7/releases). Extract its `mods`
folder into your Black Ops III game directory so the files land in
`<Black Ops III>/mods/zstats/zone/`. Select `zstats` from the game's **Mods**
menu. This route is a complete, linked standalone mod; it does not use the
Workshop source ZIP and will not update itself through Steam. The direct ZIP
includes all twelve shipped language fastfile pairs.

For BOIII, T7x, or t7-compiler, download the **Script** ZIP and run
`installer/windows/install.bat` or `installer/linux/install.sh` from its
extracted folder. Linux desktop users can also open
`installer/linux/Install ZStats T7.desktop`. The installer detects BOIII and
T7x, or accepts an explicit
game folder. The Windows installer selects `-Route BOIII`, `-Route T7x`,
`-Route AppData`, or `-Route Compiler`; supply `-CompilerRoot` for the last
route. Use `-Find`, `-Verify`, and `-Uninstall` to inspect or remove its own
files. The original BOIII AppData route is opt-in because Ezz BOIII may remove
those files on launch. On Linux, the matching flags are `--route boiii|appdata|t7x|compiler|all`,
`--to <game folder>`, `--appdata-root <LocalAppData folder>`, and
`--compiler-root <project folder>`. For example:

```text
./installer/linux/install.sh --route t7x --to "/path/to/Black Ops III" --install
./installer/linux/install.sh --route t7x --to "/path/to/Black Ops III" --verify
```

Both installers back up files they replace, restore them on uninstall, leave
modified files alone, and write an action log. `-LogRoot` on Windows or
`--state-root` on Linux selects the log directory. Run with `-Configure` or
`--configure` to see the settings route for the selected client.

BOIII and T7x carry ZStats' Lua menu and local career-PB storage; they use
`ui_scripts` rather than a linked fastfile, so the custom menu background is
not included. The t7-compiler injection carries only GSC: it has no ZStats
settings menu or client-local career-PB persistence. Its package contains
`scripts/zbundle/zstats.gsc`, a component receipt, and identical shared
`gsc.conf`/README infrastructure. Overlay compiler packages from other Z mods
into **one** compiler project, then compile and inject once. Running separate
compiler projects successively is unsupported. The installer removes only
ZStats' fragment and receipt; it leaves shared infrastructure for other
components and rejects a conflicting copy. BOIII and T7x do not use this
compiler-project route. Do not install a
loose-script route alongside the Workshop or direct-download mod.

The loose routes do not inject a separate `.csc` client script. ZStats' live
HUD and recap run from GSC, while BOIII/T7x PB storage is handled by the
included Lua `ui_scripts` notification listener. The retained `main.csc` in
the Mod Tools source is for the combined ZBundle's stock-preserving client
carrier, not a missing loose-route payload.

BOIII and T7x script users configure ZStats through **ZSTATS SETTINGS** in
the Zombies lobby or pause menu; the Lua menu persists their choices and
career PBs. The compiler-only route has no Lua menu or durable client PBs.
Set `zs_*` dvars in the console before a match instead, for example
`set zs_hud_preset detailed`.

For maintainers building from the release source, copy `ui`, `scripts`,
`zone_source`, and `dummy.cfg` into `<BO3 Mod Tools>/mods/zstats`. Copy
`source_data/zmods.gdt` and `texture_assets/zmods` into the matching top-level
Mod Tools directories, let the launcher index the GDT, then link/build both
`core_mod` and `zm_mod` with every language enabled. Players do not need these
steps to use the Workshop mod.

---

## Languages

ZStats settings are available in the game's twelve supported languages.
Translations were made by AI and may contain mistakes. If you find one, please
report it to Xep on the [Discord](https://discord.gg/RE85HRwYZZ), with the
language and the line as it reads in the game.

---

## Usage

### Live HUD

Compact is the default: **TIME**, **ZOMBIES**, **PPR**, and **KPR** in a small
top-right card. Minimal shows time and zombies. Detailed adds round time,
match earnings and kills, current-round counters, revives, and separate
**ROUND** and **ROUND KILLS** lines. Custom uses the individual row switches.
The card closes up around enabled rows, including when only the header remains.

PPR means gross points earned divided by rounds you participated in. KPR means
kills divided by those rounds. Joining a game late does not divide your totals
by rounds you missed. **EARNED** is gross match score, not your spendable
balance; it includes the points you start with.

The panel hides while the game's pause menu is open. **TOGGLE ZSTATS HUD** on
that menu hides or restores your panel for the current match only. It does not
change the saved HUD setting, stop tracking, or turn off the Game Over recap.

### Round MVP and Game Over

After a completed round, ZStats posts one MVP callout in the game feed. At Game
Over the stock scoreboard appears first, followed by paginated ZStats cards.
Solo gets a personal summary and records; co-op gets team awards and each
client's own summary. The recap covers kills, headshots, points, spending,
downs, revives, doors, barriers, perks, melee kills, round records, and
completed-round pace. Tied awards say so. Solo-only revive figures show N/A.

A partial final round contributes to the match summary, but never sets a
completed-round PB or a completed-round KPR/PPR record. Values a map cannot
provide exactly display `--` or N/A rather than a made-up zero.

---

## Configuration

Open **ZSTATS SETTINGS** in the Zombies lobby or on the game's pause menu. The
HUD and RECAP categories use the same Z Mods settings screen as the other mods.
The host controls shared HUD and recap rows. Personal PB scope, round-PB
announcements, and **RESET CAREER PERSONAL BESTS** belong to each client.
The reset asks for confirmation and clears PB records without resetting HUD
preferences.

| Setting | Default | What it controls |
|---|---|---|
| ZSTATS HUD | On | Live panel; tracking and recap stay active when it is off. |
| HUD PRESET | Compact | Minimal, Compact, Detailed, or Custom. |
| HUD POSITION | Top right | Any screen corner. |
| HUD SCALE | 100% | Panel and text size. |
| BACKGROUND OPACITY | 22% | Dark panel opacity; 0% leaves text and accent. |
| ZSTATS HEADER | On | Orange title and its spacing. |
| PERSONAL BEST MARKERS | On | Orange PB markers on eligible rows. |
| PERSONAL BEST SCOPE | Career | Saved career records or Match Only comparisons. |
| ROUND PB ANNOUNCEMENT | On | Client-only completed-round PB messages. |
| ROUND MVP | On | Round-end MVP callout. |
| GAME OVER AWARDS | On | ZStats recap after the stock scoreboard. |
| SHOW LOWLIGHTS | Off | Adds the optional Most Downs award. |
| RECAP DURATION | 20 seconds | Total time shared by the recap pages. |

Custom also exposes individual switches for match time, zombies left, PPR,
KPR, round time, earned points, round kills, round points, round headshots,
round revives, and round number. Detailed includes match kills as well as
round kills; the two do not reset together.

Career PBs cover best completed-round kills, headshot kills, melee kills,
points, revives, KPR/PPR, and fastest round, plus highest single-match
earnings, single-match kills, and round reached. A PB belongs to that player,
not the host. It survives a new match until the player resets it.

---

## How it works

ZStats reads the stock Zombies score and player counters rather than replacing
map purchase or scoring code. It observes rounds separately for each player,
freezes completed-round values at the round boundary, and keeps departing
players in the match registry for final co-op awards.

Custom maps are handled by capability: a map using the common round, score,
enemy-count, spending, and intermission paths supplies the matching stats. If
one of those paths is absent, its dependent row or award is omitted or shown
as unavailable. Exact spending depends on the stock `spent_points` event;
balance drops alone are not called purchases.

---

## Notes

- The standalone Workshop mod and ZBundle should not be enabled together.
  Select one mod from the game's Mods menu.
- The client-local pause toggle lasts for the current match. The normal HUD
  setting is the saved host/shared control.
- New PB rows are orange on both Black Ops II and Black Ops III.
- A custom map with its own startup, scoreboard, or ending script may need an
  integration even if its ordinary counters work.

---

## Testing

The 1.0 release candidate was played in solo and co-op on stock and
representative custom Zombies maps, including menus, Game Over, and career-PB
persistence. The build also passes ZStats' cross-port source, storage, and
package checks. This does not certify every custom map: one that replaces a
stock startup or ending owner may need its own integration.

---

## Ports

| Game | Repo |
|---|---|
| Black Ops II (T6) | [ZStats](https://github.com/Xeptix/ZStats) |
| Black Ops III (T7) | ZStatsT7 - you are here |

Both ports carry the same public version and setting names. The T6 edition
is installed as a Plutonium mod, while T7 has Workshop and direct-download mod routes.

---

## Other Z Mods

The other mods have their own GitHub documentation and releases:

| Mod | Black Ops III repo |
|---|---|
| ZPause | [ZPauseT7](https://github.com/Xeptix/ZPauseT7) |
| ZShare | [ZShareT7](https://github.com/Xeptix/ZShareT7) |
| ZTweaks | [ZTweaksT7](https://github.com/Xeptix/ZTweaksT7) |

[ZBundle on the Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3802815997)
combines the Z Mods in one selected mod. It has no separate GitHub repository.

---

## Changelog

### v1.2

- Kept the settings category strip at its current position after changing a
  setting, including when browsing categories farther to the right. The fix
  covers the complete mod and the supported script-loader menus.

### v1.1

- Added a separate Scoreboard HUD Preset. The normal HUD stays Compact by
  default, while holding the scoreboard shows Detailed by default. Same as HUD
  and Off are available, and the choice does not change the normal preset.
- Added BOIII, T7x, and compiler-only script routes, with installers and
  documented limits beside the complete Workshop and direct-download mod.
- Translated BOIII and T7x settings menus into twelve languages.
- Improved the live timer and personal HUD toggle when switching scoreboard
  views, plus menu behavior shared with ZBundle. PPR and KPR now display a
  consistent one decimal place instead of occasional long decimals.

### v1.0

- Initial public release for Black Ops III.
- Compact, Minimal, Detailed, and Custom live HUD presets, with a panel that
  sizes to enabled rows and hides during the stock pause menu.
- Participation-aware PPR/KPR, separate match and round kills, and orange PB
  markers for career or match-only records.
- Round MVP callouts and solo/co-op Game Over recaps after the stock scoreboard.
- Per-client career PB storage and reset; personal settings remain editable by
  a client while the host controls shared settings.
- Lobby and pause settings, a client-local pause HUD toggle, and ZBundle
  integration.

---

## Credits

- **Xep** - author
- **D3V Team** - L3akMod, used by the Black Ops III lobby menu
- **Treyarch** - the stock Zombies systems and scripts ZStats observes

## License

MIT - see `LICENSE` in the release archive. ZStats' own code is licensed under
MIT; Treyarch's game scripts and assets are not.
