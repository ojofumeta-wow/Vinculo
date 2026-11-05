# Changelog

## 0.1.4

### Added
- Beast alert is now a small on-screen panel with the family icon (never in combat; follows the alert options) instead of a chat line.

### Fixed
- Abandoning a pet now sticks: the sheet stays "Abandoned" instead of coming back as "Resting".
- A retired pet called back with a new GUID reuses its sheet instead of creating a duplicate.
- A pet is only counted as freshly tamed after a Tame Beast cast, no longer just because its loyalty is 1.
- Weekly summary window: more room between title, numbers and zones.

### Removed
- Temporary debug log (`/vinculo debug`).

## 0.1.4 (español)

### Añadido
- El aviso de bestia es ahora un panel pequeño en pantalla con el icono de la familia (nunca en combate; respeta las opciones de avisos) en vez de una línea de chat.

### Arreglado
- Abandonar una mascota ya se mantiene: la ficha queda «Abandonada» y no vuelve a «Descansando».
- Una mascota retirada que se vuelve a llamar con otro GUID reutiliza su ficha, sin duplicarla.
- Una mascota solo cuenta como recién domada tras lanzar Domar bestia, ya no por tener lealtad 1.
- Ventana del resumen semanal: más espacio entre título, cifras y zonas.

### Eliminado
- Registro temporal de depuración (`/vinculo debug`).

## 0.1.3

### Added
- Share card: a compact vertical card of your pet (portrait, numbers, achievements) made for screenshots. Open it with the card icon next to the gear, or `/vinculo card`. Move it by dragging; hover to see the close button.
- Weekly summary window on login (replaces the chat line). Repeat it with `/vinculo week`. It can be turned off in the options.
- The Bestiary can be used without a pet: the book opens there when your journal is empty.
- Pet states on the card: "Fallen" until revived, "Resting" after dismissing, "Abandoned" after abandoning it (detection of abandoning is still being checked), plus the existing "In the stable" and "In memory".
- Map marks for your wished beasts: a circle around the zone when the place is approximate, the icon where you actually saw the beast. New option to turn them off.

### Changed
- The Codex belongs to your character: deleting a pet keeps its family and prey. Achievements still go with the pet. The delete warning now says so.
- "Aún os estáis conociendo" is only shown while the pet is with you.
- Loyalty on the pet card no longer shows "(Nivel de lealtad N)".
- Pet card: "Together since" only for pets you tamed with the addon; the others show "Journal since".
- Wishes: up/down arrows move through the suggestions, Tab picks the highlighted one.

### Fixed
- Taming is recognised in Forever (new spell ID for Tame Beast).
- The Feed button now works (it uses a macro).
- "View map" opens the map for zones the client lists differently, and says so when it can't.
- The weekly summary no longer counts a pet's whole life when its internal ID changes.
- Opening the book with food in your bags can no longer fail on an item function.
- The "Fallen" tag no longer sticks to a pet you put in the stable.
- Long pet names fit on the card and the weekly window.

### Known issues
- Abandoning or releasing a pet may still show "Resting" instead of "Abandoned".
- A retired pet called again with a new internal ID may create a second journal.
- Each beast has a single zone in the Bestiary, and the data is for Classic.
- If you change the game language, zone names may appear twice in Journeys.

## 0.1.3 (español)

### Añadido
- Tarjeta para compartir: una ficha vertical y compacta de tu mascota (retrato, cifras, logros) pensada para capturas. Se abre con el icono de tarjeta junto al engranaje, o con `/vinculo tarjeta`. Se mueve arrastrando; al pasar el ratón sale la X para cerrarla.
- Resumen semanal en una ventana al conectarte (sustituye a la línea de chat). Se repite con `/vinculo semana` y se puede apagar en las opciones.
- El Bestiario se puede usar sin mascota: el libro se abre ahí cuando el diario está vacío.
- Estados de la mascota en su ficha: "Caída" hasta revivirla, "Descansando" al despedirla, "Abandonada" al abandonarla (la detección del abandono aún se está comprobando), además de "En el establo" y "En el recuerdo".
- Marcas en el mapa de tus bestias deseadas: un círculo alrededor de la zona cuando el lugar es aproximado, y el icono donde viste la bestia de verdad. Nueva opción para apagarlas.

### Cambiado
- El Códice es de tu personaje: al borrar una mascota se conserva su familia y sus presas. Los logros siguen yéndose con la mascota. El aviso de borrar ahora lo dice.
- "Aún os estáis conociendo" solo sale mientras la mascota está contigo.
- La lealtad en la ficha ya no muestra "(Nivel de lealtad N)".
- Ficha de la mascota: "Juntos desde" solo en las que domesticaste con el addon; las demás muestran "Diario desde".
- Deseos: las flechas arriba/abajo recorren las sugerencias y Tab elige la marcada.

### Corregido
- La domesticación se reconoce en Forever (nuevo ID de hechizo de Domar bestia).
- El botón de alimentar funciona (usa una macro).
- "Ver mapa" abre el mapa en zonas que el cliente lista de otra forma, y avisa cuando no puede.
- El resumen semanal ya no cuenta toda la vida de la mascota cuando cambia su identificador interno.
- Abrir el libro con comida en las bolsas ya no puede fallar por una función de objetos.
- La etiqueta "Caída" ya no se queda pegada a una mascota que guardas en el establo.
- Los nombres largos caben en la tarjeta y en la ventana del resumen.

### Problemas conocidos
- Al abandonar o liberar a una mascota puede seguir saliendo "Descansando" en vez de "Abandonada".
- Una mascota retirada que vuelves a llamar con otro identificador interno puede crear un segundo diario.
- Cada bestia tiene una sola zona en el Bestiario, y los datos son de Classic.
- Si cambias el idioma del juego, los nombres de zona pueden salir duplicados en Viajes.

---

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
