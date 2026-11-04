# Borrador para CurseForge – Vínculo

## Pestaña "Choose Game"
World of Warcraft.

## Pestaña "General"

**Project name** (sin la clase, la categoría, la versión ni el nombre del juego):
```
Vinculo - Pet Journal
```

**Logo:** sube `logo/logo.png` (512×512). Si lo cambias, edita `logo/logo.svg` y ejecuta `node _luatest/render-logo.js`.

**Summary** (en inglés, una frase):
```
A leather-bound hunter pet journal: history, achievements, travels, a bestiary with autocomplete and map, one-click feeding and more.
```

**Main category:** `Hunter` (dentro de Class)

**Additional categories:** `Achievements`, `Roleplay`

**Allow Comments:** ✅ marcado (sirve para que te avisen de errores)

**Unlisted project:** ✅ marcado mientras lo pruebas en el juego; desmárcalo cuando funcione bien.

**Social Links:** opcional (Discord, GitHub…).

## Pestaña "Description" (en inglés)

```markdown
# Vínculo (Vinculo) – Hunter Pet Journal

Every hunter has a story with their pet. **Vínculo writes it down for you**, in a leather-bound journal with a page for every pet you have ever had: the day you met, every fight you survived, every zone you walked together.

It is the only hunter pet journal with a **bestiary that shows you on the map where to tame your next beast**, and it is made to stay out of your way.

## Quick start
1. Install it and log in. Your current pet already has a page.
2. Type `/vinculo` (or click the minimap button) to open the journal.
3. Play as usual: the story, stats and achievements fill in by themselves.
4. In the Bestiary, type a beast's name to add it to your wish list, then press **Show map**.

## A journal that looks like a journal
A hand-drawn book with leather pet tabs, ink-style controls and its own fonts. Open it with `/vinculo` or the minimap button.

## What it records
- **The day you met**: date and zone where you tamed (or first summoned) your pet.
- **Stats**: 8 stat medallions with a one-line story of your pet; hover for all 12 (fights survived, bosses defeated, zones and dungeons visited, time together, time in combat, meals, falls, revives and best streak).
- **History**: a dated timeline of your adventure – level ups, loyalty, first boss kills, new zones, renames…
- **21 achievements** of its own, like *Best friend*, *Untouchable* or *A year of adventures*, shown as medals with progress towards the next one.
- **Journeys**: every zone you have visited together, grouped by continent.
- **Personality**: your pet becomes *Glutton*, *Reckless*, *Wanderer*, *Giantslayer*, *Tireless*, *Unbreakable*, *Loyal* or *Faithful* depending on how you play together.
- **Anniversaries** and a short **weekly summary**, one chat line each.
- **Memory**: pets you abandon can be kept "in memory" instead of deleted.
- **Share** your pet's card with your party, raid or guild, or **export** its story as text.

## Bestiary: plan your next tame
- A **wish list of beasts to tame**, with **autocomplete**: type "wolf" and pick one; its zone fills in on its own.
- A **Show map** button on every wish opens the world map at the zone and marks it with the Vínculo icon (the centre of the zone, or the places where you have already seen the beast).
- A **Codex** of the hunter pet families (silhouettes until you meet them) and a list of **Challenges**.
- **Beast tooltips**: hover a beast to see if it is on your wish list, which pet skill it teaches and whether you have already tamed its family.
- An **alert** when you spot a beast from your wish list (never in combat).

## Feed your pet in one click
A round badge next to your pet's portrait picks the best food in your bags for your pet. One click and it eats. (Out of combat only, like the game itself.)

## Your pet talks (optional)
Your pet can comment on your adventures in chat. Only you see it, and you can turn it off.

## Designed not to get in your way
- Every notification can be turned off in the settings, inside the book.
- Achievements can notify in chat only, with no popup.
- The minimap button can be hidden; no login spam.
- Fade animations can be turned off.
- Information only: it never tells you what to do in combat, following WoW: Forever's addon rules.

## Commands
- `/vinculo` or `/diario` – open the journal
- `/vinculo toasts` – toggle achievement notifications
- `/vinculo share` – share your current pet's card
- `/vinculo export` – export your pet's story as text

## How it counts
WoW: Forever does not let addons read the combat log, so Vínculo counts **fights survived** (the fight ends with you and your pet alive) rather than kills.

## FAQ
**Does it do anything in combat?** No. It only counts and records; it never tells you what to do, and the feed button only works out of combat, like the game itself.

**Why "fights survived" and not kills?** WoW: Forever does not let addons read the combat log. A fight counts when it ends with you and your pet alive.

**My pet got renamed or I changed the game language. Will it duplicate?** No: pets are matched by name and family, in either language.

**How do I turn off notifications, the minimap button or the pet's chat lines?** Everything is in the settings inside the book.

**Can I take my pet's story with me?** Yes: `/vinculo share` for your party, or `/vinculo export` for the text.

## Good to know
- Beast, zone, food and skill data are for Classic; WoW: Forever may have more, and they will grow with updates.
- Available in English and Spanish.
- Known issues: each beast has a single zone; if you change the game language, zone names may appear twice in Journeys; zones visited with an older version keep their old continent until you visit them again.
- Found a bug? Leave a comment with the exact Lua error text (`/console scriptErrors 1`) and I'll fix it.

*Fonts: IM Fell English and Caveat, SIL Open Font License.*
```

## Galería (Images)
Activa el **carrusel** en la página de imágenes y ordénalas así (lo más importante primero). Las imágenes montadas están en `dist/galeria/`:
1. `01-ficha-historia` (qué es)
2. `02-bestiario-autocompletar`
3. `06-ver-mapa`
4. `03-logros-tooltip`
5. `07-tooltip-bestia`
6. `05-aviso-logro`
7. `04-viajes` (cuando la rehagas con el hotfix)

## Social links
En la pestaña General, añade un enlace (Discord o GitHub) para que reporten errores: la guía de CurseForge lo recomienda.

## Pestaña "License"
**MIT License**: cualquiera puede usar y modificar el código, siempre que mantenga tu nombre. Si prefieres que nadie lo reutilice, elige **All Rights Reserved**.

## Al subir el archivo
Sube un `.zip` que contenga la carpeta `Vinculo` (sin `_luatest`). Marca como versión del juego **WoW Forever (1.60.1)** y tipo de lanzamiento **Beta** hasta que lo hayas probado.
