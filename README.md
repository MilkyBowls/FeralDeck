# Feral Deck - Field Journal

Install in `World of Warcraft/_forever_/Interface/AddOns/FeralDeck/`, enable the addon, and open **/fd**.

## First expedition

1. Defeat creatures as you quest. Each credited kill has a rarity-based chance to award your first copy, with a guarantee on the tenth credited kill of that NPC ID. FeralDeck uses readable kill credit, combat participation followed by a witnessed death, or attributable corpse loot. On Forever, a tracked target or nameplate can count before you open the corpse. Looting is still a fallback. Fishing, item-origin loot, and unreadable loot sources are excluded. Hover an uncollected creature to see first-copy progress.
2. The first discovery shows a click-through portrait and chime, including while **/fd** is closed. Closely spaced discoveries wait their turn. In **Field Journal**, unread cards appear first with the wolf-seal back. Hover to see the creature name and click to turn over the card. Reduced motion shows the portrait immediately. Click the inspector to skip its reveal. Hover or hold the left button and drag to inspect the art. The inspector shows creature types, Solo Battle moves, and Mastery progress. Field Notes covers repeat rolls, prestige, and synergies.
3. Own three distinct creatures and choose **Equip first three** to equip them and open Battle. **Add to draft** carries the inspected creature to the tabletop. Click the destination slot to place it. If that creature already occupies another slot, the two trade places. **Save and equip** commits the named draft. **Wolf Pack** and **Mine Guard** offer editable recipes.
4. Choose **Sentinel** for a Frost team, **Prowler** for a Pack team, or **Veteran** for an opponent that uses tactics and scales Mastery to your roster's average tier, with a minimum of tier 4. The gold tile on the initiative rail marks the next creature to act. Choose a move for the ready ally and, if it needs a target, hover a rival to preview the damage, shield breaks, and synergies. Click the rival card to commit, or select its name and click **Confirm target**.

## Area atlas and statistics

In **Collection**, open **Areas** to see each area's collected and uncollected counts. Every catalog area appears regardless of tracking or ownership, including areas where you have zero cards. Creature entries reveal their names after you obtain a copy. The loading bar shows progress indexing the available creature or area catalog. A creature found in multiple areas can contribute to each area but counts once toward the account total. **Statistics** shows collected and uncollected cards, lifetime copies, kills, mastery, prestige and match results.

The atlas combines authored habitats, discoveries with recorded locations, and the installed FieldGuideForever catalog when available, or the installed QuestieDB spawn catalog and client map information. FeralDeck reuses the completed area catalog after login or reload. It refreshes the index when the selected provider, provider version, game build, locale, or catalog format changes. The previous index stays available while a refresh runs or when no provider is available. Catalog counts are estimates of the available roster. Some entries may have limited spawns or may not expose eligible corpse loot. Overworld beasts and hostile humanoids with incomplete catalog metadata can qualify through in-game observations or attributable corpse loot. Verified faction-affiliated overworld encounters, such as Durotar's Kul Tiras Sailors, Marines, and Lieutenant Benedict, are eligible. Ordinary faction NPCs, service NPCs, and player-controlled units are excluded. Collected creatures use observed rarity and location where available, plus a type and moveset derived from their species. Tooltips and enemy nameplates show **Collected** or **Uncollected** when the client exposes their creature identity.

## Creature moves and types

Each Solo Battle creature has four named moves. Attacks and guard moves build Focus. Techniques cost 1 Focus and can mark, break shields, delay an enemy, drain Focus, or reinforce the acting creature. Signatures require 2 Focus and may refund some of that cost. Featured creatures have individual moves, while other creatures draw from their type's moveset. A secondary type usually supplies the technique.

The 18 types are Pack, Feral, Brute, Burrow, Martial, Trickster, Tide, Shell, Venom, Winged, Frost, Ember, Stone, Storm, Verdant, Arcane, Undead, and Fel. The journal derives types from creature identity and recorded family, with Martial as the fallback when it lacks a more specific match. Hunter, Keeper, and Hexer continue to determine Solo Battle speed and HP.

### Team synergies

FeralDeck checks both type and moveset on different cards in your roster. A pairing requires a setup move on one card and a compatible follow-up on another. Most mixed-type pairings require the follow-up on the next allied action. A shield break or Focus drain must remove something to prime its combo. If the rule refers to the same rival, switching targets drops the follow-up.

| Synergy | Types | Setup and payoff |
| --- | --- | --- |
| Pack Hunt | Pack + Pack | One Pack ally marks a rival. A different Pack ally consumes the mark for +2 damage. |
| Hold the Tunnel | Burrow + Burrow | One Burrow ally breaks shield. A different Burrow ally's shield-granting move adds +2 shield. |
| Whiteout | Frost + Frost | One Frost ally uses a shield-granting move. A different Frost ally's damaging move breaks up to 2 shield on a shielded rival. |
| Rime Shot | Frost + Winged | A Frost delay move followed by a Winged hit against the same rival breaks up to 2 shield. |
| Steam Burst | Tide + Ember | A Tide delay move followed by an Ember finisher against the same rival breaks up to 2 shield. |
| Tailwind | Storm + Winged | A Storm delay move followed by a Winged piercing move advances that ally's next turn by 2 ticks. |

See a collected card's **Synergies** page for eligible partners and compatible move chains. Hover a pairing for all of its setup and follow-up moves. The battle stage shows open combos. Its tooltip lists the living allies, follow-up moves, targets, and expiry conditions.

## Display and feedback

Action colors are consistent across the journal, deck builder, and battle. Tactics are blue, signatures purple, techniques teal, guard moves yellow, and attacks red.

The primary creature type sets the color and engraving of its card frame. Both type badges appear on dual-type cards. The habitat supplies the scenery and is listed beneath the badges on the full card.

Use the controls in the top bar on any page. **Motion** switches between full effects and reduced motion. Reduced motion skips the flip, glints, pointer motion, meter animation and combat flourishes. **Sound** controls FeralDeck audio on WoW's SFX channel. **Size** switches between fit and large text and controls for TV play. Both sizes fit within the available game window. These preferences persist across reloads. The addon uses the game's native controller input while the FeralDeck window is open. It adds no global bindings and makes no changes to Steam Input.

### Controller navigation

Open **/fd** and press the D-pad to show the focus ring. Use the **D-pad** to move, **A** to select, **B** to go back or close, **X** for help on the focused control, and **LB/RB** to switch between Field Journal, Deck Builder, and Battle. In Solo Battle, focus a rival to preview the armed move and press **A** to confirm.

Select a search, deck-name, or duel-name field to open the on-screen keyboard. Use **Y** or **Done** to apply the text and **B** to cancel. Controller navigation starts enabled. Toggle it in **Settings**.

In Solo Battle, the **Initiative** timeline is above both teams. Select a card from the **Tactics** hand on the right to queue it for the next move. The **Team synergies** panel shows which combos are primed and opens their setup and payoff details. Whiteout shows the creature that primed it and previews the shield break on eligible rivals. Whiteout uses a Frost ally's habitat for the battle backdrop when available. **Show combat log** opens the history in the battlefield area, with the timeline and tactics still visible. **Playback** switches between normal and fast timing.

Solo victory shows the creatures that acted and earned mastery, their before-and-after values, and any perk crossed. A defeat can report shield absorption or actual HP lost. **Rematch** starts the same solo opponent or sends a new invitation to the same duelist. **Edit Deck** opens the equipped roster.

The Field Journal and Deck Builder have independent search and role filters. Search by creature name, type, or NPC ID. Select a card for its move previews and earned perks. **Move details** opens the card's current solo move totals, Mastery bonuses, and situational effects. **Battle stats** and **Records** retain separate solo and duel histories. **Synergies** lists compatible cards in your collection and their Solo Battle effects. Select a partner to open its card. In **Areas**, select a habitat to see its collected cards and catalog progress.

Asset sources, licenses and filenames are in the [asset manifest](ASSETS.md).

## Progression

Every earned copy adds 1 mastery, including the first copy. The upgrade credits existing lifetime copies once. Mastery perks unlock automatically and never spend copies. After discovery, each eligible kill of that creature grants **1 mastery**. A completed solo victory grants **1 mastery** to each owned creature that acted. Solo Battle has **25 Mastery tiers**, starting at **3 XP** and ending at **1,400 XP**. The first four perks unlock at 3, 7, 12, and 20 XP. At 20 XP the card upgrades its technique: it can break extra shield, add delay, drain extra Focus, gain extra shield, or refund its Focus cost, depending on the move. Damaging techniques also gain 1 damage. Later shield-breaking perks apply to rival-targeting techniques. Later perks improve conditional attack, shield, Focus, and turn-order effects. Collection shows progress between milestones, and **Field Notes > Perks** lists the card's earned perks. Concessions and aborted matches award no mastery.

The chance before the first-copy guarantee is **Common 2%**, **Elite 1.8%**, **Rare 1.5%**, **Rare elite 1.2%**, and **Legendary 1%**. After discovery, eligible corpse loot uses those same chances and guarantees repeat copies after 10, 12, 15, 18, or 22 rolls respectively. Spawn GUIDs deduplicate kill credit and loot across reloads, and NPC IDs identify cards. The displayed yield uses copies divided by tracked kills.

Prestige spends **100 copy progress** and preserves lifetime copies and mastery. Each rank adds a foil treatment. First prestige grants Channel, which adds 1 Focus to the card's solo guard move. Old saves preserve earned tiers, copies, prestige, decks, tactics, and records. Legacy loaners remain playable in the deck builder. New saves start empty. Old loot data lacks the sequence of copies and misses, so repeat guarantees start from zero on upgrade.

### Featured field guide

All eight feature cards are sourced from their namesake creatures in Elwynn Forest. Spawn and identity references are community data from the [Forever Elwynn atlas](https://zephras.com/forever/enUS/zone/12/) and [WoW Forever player observations](https://wowcensus.io/forever/npc/). The signatures below are Feral Deck rules.

| Creature | NPC ID | Solo signature |
| --- | ---: | --- |
| Young Wolf | 299 | Scent of Blood gains 2 damage against marked rivals |
| Young Forest Bear | 822 | Den Guard grants shield and carries unused shield through the next action |
| Kobold Miner | 40 | Pickaxe Split breaks up to 4 shield before damage |
| Stonetusk Boar | 113 | Headlong Rush gains 2 damage against unguarded rivals |
| Prowler | 118 | Pack Signal marks the rival |
| Murloc Streamrunner | 735 | Slipstream refunds 1 Focus |
| Defias Cutpurse | 94 | Cut the Purse drains 1 rival Focus |
| Kobold Laborer | 80 | Reinforce grants extra shield when already guarded |

### Solo Battle rules

Use **Auto Battle** during a solo match to let the AI choose legal moves and optional tactics. **Pause Auto Battle** returns control after any action in playback. Leaving the Battle screen suspends auto-play. Each new match starts with manual control. The solo AI checks the next allied action for a viable payoff before favoring a combo setup. The deck optimizer uses the same planner to compare its shortlisted rosters and tactics.

Solo Battle schedules all six creatures individually. Hunter Speed is 9, Hexer Speed is 8, and Keeper Speed is 7. Each creature normally recovers in 16 minus its Speed ticks. Both teams use the same rules. Equal turn times rotate from the previous actor. Moves and synergies can advance an ally's next turn or delay a rival. The timeline shows the next six turns assuming normal recovery. Each creature has its own HP, shield, and mark. Focus is shared by the team. Pick a move and click a highlighted rival when it requires a target. Hover for a preview of damage, shield breaks, delay, synergies, and knockouts. Self-targeted moves resolve immediately unless an offensive tactic requires a rival target. Defeated creatures drop out of the turn timeline. Defeat all three rivals to win. If a Solo Battle reaches 60 actions, the team with more remaining HP wins.

Select up to three distinct tactics. Solo Battle starts with all selected tactics in hand. Old loadouts retain their first three distinct valid tactics in slot order. Commit at most one with a creature action. It goes to discard, and a replacement arrives after the rival acts. When the draw pile runs out, the discard pile returns in play order. Selecting a tactic previews it and can be undone before committing. Friendly duels continue using their existing signature rules and protocol.

An acting creature loses up to 2 shield if a rival acted since its last action, unless its previous move carried shield forward. Consecutive allied guard moves grant 2 less shield. After a creature takes HP damage, its non-consecutive guard builds at least 2 Focus when its team has less than 2.

## Play Relay

In **Decks**, select a slot and click an owned card to fill it. Equip three distinct NPC IDs. **Save and equip** updates the named deck. Enter another name to keep a separate build. **Saved decks** opens the deck list.

In a friendly duel, each side starts at 34 health and one focus. On your turn, select a move on any ready card. That card rests until another ally acts. Strike deals Power and gains one focus. Brace gains three shield and one focus. Focus caps at three and shield caps at six. Signature costs two focus.

* **Hunter** pierces shields with Pounce. Save it for a guarded enemy.
* **Keeper** deals damage and gains three shield with Bulwark.
* **Hexer** marks the opponent with Brand. The next damaging action consumes the mark for three extra damage before shields. Follow Brand with Pounce to carry that bonus through guard.

Signatures gain one damage against a favorable role and lose one against an unfavorable role. Hunter beats Hexer, Hexer beats Keeper, and Keeper beats Hunter. The defending role belongs to the rival's last active card, or its first card on the opening turn. The command panels calculate projected HP loss using the same resolution rules as the committed move. Friendly duels use the existing wire protocol and role signatures.

Reduce enemy health to zero. After 48 actions the higher remaining health wins, with equal health scored as a draw. The battle history records damage after shields, marks, shield generation and upgraded actions.

For a friendly duel, both players enable the same addon version and enter the open world. Enter the other character’s name (or Name-Realm) under **Battle**, then click **Challenge**. The recipient opens **/fd -> Battle -> Accept**. The challenger opens play. PvP uses base power, roles and shared rules. Foil ranks are cosmetic in duels. Invitations expire after 45 seconds and a silent turn expires after two minutes. Concession records a loss. An interrupted or expired session closes locally without scoring. Records and collection claims are local and editable.

## Forever compatibility and verification

Checked November 25, 2026 against the installed Forever build **1.60.1.71091**, local addon TOCs (16001) and installed examples of loot-source attribution and addon whispers. This is an independent fan addon.

* On Forever, FeralDeck watches the current target and visible enemy nameplates for deaths after it observes player or pet combat participation. A readable spawn GUID ties death and loot to the same kill. Loot also snapshots readable source GUIDs at LOOT_READY and processes them at LOOT_OPENED so fast auto-loot has a second path. Fishing, item-origin loot, and non-creature sources are excluded. Encounters with neither a trackable death nor an attributable loot source can still go uncounted. [Forever player test of GetLootSourceInfo](https://eu.forums.blizzard.com/en/wow/t/feature-request-area-aoe-looting-for-multiple-corpses/633131) · [Blizzard loot UI source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/LootFrame.lua)
* Duels use registered C_ChatInfo addon whispers and check messaging lockdown, instance state, trial restrictions and send results. Both players should leave restricted locations before trying again. Actual delivery also depends on the client and recipient being reachable. [Forever addon communication logger](https://github.com/bastianh/AddonCommLog) · [Blizzard chat API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua)
* The Lua harness covers loot duplication and secrecy, migration, progression, match rules, peers and panel navigation. From the addon directory run `lua tests/run.lua`, or run `lua FeralDeck/tests/run.lua` from its parent. No original Feral Deck source or save was present. Migration fixtures exercise NPC-keyed cards/collection, copies, equipped/deck, saved decks and win/loss totals. Compatibility with other historical save layouts is unverified.
### Field Journal verification

- **In the installed Forever client:** reloaded the addon, opened the journal on an existing four-creature save, and observed the parchment, forest panel, landscape art, borders, creature models, role/signature text and mastery display at 1920 x 1080. A blocked-action dialog appeared on that reload. The final code skips restricted combat-log registration on the Forever interface.
- **Lua 5.3 harness:** exercised both discovery event orders, duplicate delivery, simulated reload, closed-panel toast queuing, New, reveal skipping, pointer/drag return, Collection-to-Deck placement, named deck saving, tactics, projected damage, solo and incoming duel playback, wins, losses, concessions, draws and interruptions. A victory crossing a perk threshold checks the actual award and verifies that repeated finish/refresh calls grant no extra mastery or victory cue.
- **Scale and assets:** checked panel and control bounds at 800 x 600, 1280 x 720 and 1920 x 1080 with large sizing. All six TGA files decoded with power-of-two dimensions. Windows Media Foundation decoded all nine MP3s to PCM.
- **Remaining live checks:** a fresh corpse discovery and reveal, drag and placement, full win/loss playback, reduced motion, audio audibility, small-window text clipping, TV-distance readability and an actual two-player duel. The final registration change still needs a live reload check.




Area profile references: [Arathi Basin](https://warcraft.wiki.gg/wiki/Arathi_Basin_(original)) and [Eastern Kingdoms landmarks](https://warcraft.wiki.gg/wiki/Exploration_achievements). Creature profiles combine recorded habitat data with FeralDeck battle notes. Entries without a specific sighting leave the landmark unknown.

The collectible catalog covers eligible overworld creatures. FeralDeck excludes Alliance- or Horde-friendly NPCs, service NPCs, vehicles and instance loot. When eligibility cannot be verified, an NPC is omitted. Previously saved cards and decks are retained, with unverified cards hidden until their eligibility is established.
