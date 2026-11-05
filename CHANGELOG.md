# Changelog

## 0.1.2

### Fixed
- Journeys: continents are no longer duplicated after changing the game language (this also merges older entries saved in the other language).

### Changed
- Pet card: "Together since" now only shows for pets you tamed with the addon active; pets you already had show "Journal since".
- Wishes: up/down arrows move through the suggestions, and Tab picks the highlighted one.

### Known issues
- If you change the game language, zone names may appear twice in Journeys.
- Each beast has a single zone in the Bestiary, and the data is for Classic.
- First run on WoW: Forever: some features (map button, feed badge) are still being checked.

## 0.1.2 (español)

### Corregido
- Viajes: los continentes ya no se duplican al cambiar el idioma del juego (también une los datos antiguos guardados en el otro idioma).

### Cambiado
- Ficha de la mascota: "Juntos desde" solo sale en las que domesticaste con el addon activo; las que ya tenías muestran "Diario desde".
- Deseos: las flechas arriba/abajo recorren las sugerencias y Tab elige la marcada.

### Problemas conocidos
- Si cambias el idioma del juego, los nombres de zona pueden salir duplicados en Viajes.
- Cada bestia tiene una sola zona en el Bestiario, y los datos son de Classic.
- Primer uso en WoW: Forever: algunas funciones (botón del mapa, insignia de alimentar) aún se están comprobando.

---

## 0.1.1

### New
- **New look**: a leather-bound book with hand-drawn pages, leather pet tabs, ink-style controls and custom fonts (IM Fell English and Caveat).
- **Pet page**: round portrait, 8 stat medallions with a one-line story, and a tooltip with all 12 stats.
- **History** as a timeline, **Achievements** as a medal grid with progress, and **Journeys** grouped by continent.
- **Achievement alerts** now use the game's own achievement banner, with the Vínculo logo.
- **Bestiary**: a wish list of beasts to tame with **autocomplete** for beasts and zones (type "wolf" and pick one; its zone fills in), a **Codex** of the hunter pet families and **Challenges**.
- **Show map** button on every wish: opens the world map at the zone and marks it with the Vínculo icon (the centre of the zone, or the places where you have already seen the beast).
- **Feed your pet in one click**: a round badge by the portrait uses the best food in your bags.
- **Beast tooltips**: shows if a beast is on your wish list, which pet skill it teaches and whether you have tamed its family.
- **Alert** when you spot a beast from your wish list (never in combat).
- **Your pet can talk** in chat (only you see it). Optional.
- Minimap button (can be hidden) and settings inside the book.
- Gentle fade animations, with an option to turn them off.

### Fixed
- A pet no longer gets a duplicate page after relogging or after changing the game language.
- Icons no longer show a square border inside their rings.
- Smoother edges on the book.

### Notes
- Beast, zone, food and skill data are for Classic; WoW: Forever may have more.
- Tested on MoP Classic; first run on WoW: Forever. Please report errors with the exact Lua error text.

---

## 0.1.1 (español)

### Novedades
- **Nuevo aspecto**: libro de cuero con páginas dibujadas, pestañas de cuero para cada mascota, controles a tinta y fuentes propias.
- **Ficha**: retrato redondo, 8 medallones de estadísticas con una frase y un tooltip con las 12.
- **Historia** como línea de tiempo, **Logros** en rejilla con progreso y **Viajes** por continente.
- **Avisos de logro** con el cartel de logro del propio juego y el logo de Vínculo.
- **Bestiario**: lista de deseos con **autocompletar** de bestias y zonas (escribe "lobo" y elige; la zona se rellena sola), **Códice** de familias y **Retos**.
- Botón **Ver mapa** en cada deseo: abre el mapa en la zona y la marca con el icono de Vínculo (el centro de la zona o los lugares donde ya has visto la bestia).
- **Alimentar con un clic**: una insignia junto al retrato usa la mejor comida de tus bolsas.
- **Tooltip de bestias**: si está en tu lista, qué habilidad enseña y si ya has domesticado su familia.
- **Aviso** al ver una bestia de tu lista (nunca en combate).
- **Tu mascota habla** en el chat (solo tú lo ves). Opcional.
- Botón del minimapa (se puede ocultar) y ajustes dentro del libro.
- Fundidos suaves, con opción para quitarlos.

### Corregido
- La mascota ya no se duplica al reconectar ni al cambiar el idioma del juego.
- Los iconos ya no enseñan un borde cuadrado dentro del anillo.
- Bordes del libro más suaves.

### Notas
- Los datos de bestias, zonas, comidas y habilidades son de Classic; Forever puede tener más.
- Probado en MoP Classic; primer uso en WoW: Forever. Si ves un error, mándame el texto exacto del error de Lua.
