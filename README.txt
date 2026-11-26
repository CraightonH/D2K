D2K 0.2.1 — WoW Forever (Interface 16001)

D2K adds compact distance estimates to friendly and enemy nameplates.
Enemy indicators change color based on your hovered spell, current cast,
or last successful cast, helping you develop a feel for spell range.

GETTING STARTED
Install the D2K folder into World of Warcraft\_forever_\Interface\AddOns.
The TOC must be at Interface\AddOns\D2K\D2K.toc. Enable D2K in the AddOns list.
Enable enemy nameplates with V and friendly nameplates with Shift+V, or your
configured nameplate bindings. Restart the client after adding new files.

Labels appear beneath visible nameplates without targeting or hovering.
The default display is a small crosshair and a 9-point distance number.
Open /d2k to customize the appearance and behavior.

DISTANCE NUMBERS
25 means within 25 yards. Confirmed upper limits round UP to the next 5 yards.
? means no usable upper limit. A lower bound alone cannot mean "within."
The display interval does not guarantee measurement precision: friendly
checks can have wider gaps than enemy checks. These are estimates, not
exact yardage. Hitboxes and targeting rules can affect range answers.

SPELL SELECTION
Priority: hovered offensive ranged spell, current cast/channel, last
successfully cast offensive ranged spell. Hovering a supported spell in an
action bar or spellbook previews it temporarily. Cast-start events select
its range immediately. Successful casts keep that spell selected afterward.
Interruptions and failures restore the last successful selection. Utility,
self-centered AoE without a reported casting range, other players' casts,
and hidden spell IDs do not replace the saved last successful spell.
Custom action bars must provide standard tooltip spell data or tooltip hooks.

Enemy text and icons are green for in range, red for out of range, and neutral
when unknown by default. Range does not establish line of sight, facing,
resources, cooldown readiness, immunity, or every targeting requirement.
For a spell with a minimum range, OUT may also mean too close.

FRIENDLY NAMEPLATES
Friendly labels use helpful spell checks and friendly item checks, plus
positive near/nearby interaction checks outside combat. Confirmed direct
group-member distance is preferred when the client provides it. Offensive
spell coloring does not apply to friends. The player's own plate is excluded.
Friendly item and interaction checks are skipped in combat. Forbidden
nameplates are skipped. Data may be unavailable in instances or combat.

Unknown, secret, uncached, failing, or contradictory checks never become
invented distances. Unknown labels can be hidden in settings. Item probes
do not use, equip, or require possession of the items; only cached client
range data is queried. D2K does not draw world or terrain range overlays.

SETTINGS
Configure friendly/enemy visibility, distance/spell/status text, font size,
outline, position, offsets, text and background opacity, range colors,
update interval, unknown visibility, and boundary-crossing pulses.
Pulses reset when the selected spell changes or range information is lost.

ICONS
Open /d2k > Range icon... for searchable thumbnails and source filters.
Built-in choices: crosshair, circle, bullseye, diamond, brackets, and dot.
Round shapes use bundled antialiased transparent textures. Native raid
markers are also available. These choices need no other addon.

The optional library indexes 809 textures in the installed ForeverAuras
Assets and Emojis collections. Texture files remain in ForeverAuras; no
ForeverAuras code or media is bundled. Missing textures fall back to the
built-in crosshair. A custom texture path or numeric file ID is supported.

Icons scale with text by default. Base icon size is the size at 9-point text
(default 10). Disable Scale icon with text for a fixed independent size.
Show/hide icons, change size and spacing, or disable tint to preserve native
texture colors. The combined icon and number stay centered under the bar.

COMMANDS
/d2k              Open settings (also Options > AddOns > D2K).
/d2k on           Enable overlays.
/d2k off          Hide overlays.
/d2k clear        Forget the last successful ranged spell.
/d2k reset        Reset settings; keep the last successful ranged spell.
/d2k debug        Print client build, selected spell, tracked nameplate count,
                  and available checks for the current hostile/friendly target.

DATA
Appearance settings: D2KDB (account-wide).
Last successful spell: D2KCharacterDB (per character).
The addon folder, TOC, UI frames, settings category, media paths, commands,
and saved variables all use D2K. No historical command aliases or profile
migration logic are included.

VALIDATION
Lua 5.1 syntax and simulated client checks cover selection priority,
casting/channels, unavailable and secret data, individual and recycled
nameplates, settings, icons, scaling, and friendly distance fallbacks.
Simulated checks do not replace visual verification in the actual client.

REFERENCES
Blizzard API source: https://github.com/Gethe/wow-ui-source/tree/forever
Range thresholds: https://github.com/WeakAuras/LibRangeCheck-3.0
