# D2K client verification

Record the addon version, client version/build, interface, class, and other enabled addons when reporting a problem. The template's upstream commit is a research baseline, not a claim that this client build has been tested.

Before a public release, install the packaged ZIP and check:

- The folder/TOC names are D2K and all three bundled round textures render, including at small UI scales.
- Visible friendly and enemy plates show labels without targeting or hovering; the player's own plate is excluded.
- A hovered offensive ranged spell overrides the current cast; leaving the tooltip restores the active cast, then the last successful spell.
- Casts/channels update immediately. Interruptions and failures restore the prior successful selection; unrelated or late events do not clear a newer cast.
- Friendly range checks remain separate from offensive-spell colors. Test near, medium, and distant allies, group members, town crowds, combat, and instances.
- Unknown, restricted, or conflicting data displays `?` or hides according to settings.
- Icon choice, size, spacing, tint, text scaling, fonts, position, colors, and opacity apply and survive a reload.
- Built-in icons work without ForeverAuras; library choices use its installed files and missing paths fall back to crosshairs.
- Fresh D2K settings and existing D2K settings work across reloads and character changes.
- Nameplate reuse, visibility changes, large pulls, and crowded towns do not leave stale labels or generate Lua errors.

Saved variables are `D2KDB` (account-wide preferences) and `D2KCharacterDB` (last successful spell). There are no historical command aliases or profile migrations.
