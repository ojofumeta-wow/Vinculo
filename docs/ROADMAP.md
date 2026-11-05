# Roadmap de Vínculo

Versión actual: **0.1.0** (beta, sin probar en el juego real).
Marca cada tarea con `[x]` cuando la termines.

## Objetivo técnico

| | |
|---|---|
| Cliente | **WoW Forever** solamente (no Retail, no Classic Era) |
| Versión comprobada | 1.60.1.70532, interfaz `16001` |
| Fuente de la API | `wow-ui-source` commit `ca8368f2f2380cbe696854f7f2646387c278a61b` (skills en `.claude/skills`) |

Estado de las APIs según esa fuente (declarada no significa probada en el juego):

| Estado | APIs y eventos |
|---|---|
| Declaradas para Forever | `UnitExists`, `UnitGUID`, `UnitName`, `UnitCreatureFamily`, `UnitLevel`, `UnitIsDead`, `UnitIsDeadOrGhost`, `UnitClass`, `IsInInstance`, `GetInstanceInfo`, `GetRealmName`, `IsInGuild`, `C_PetInfo.GetPetLoyalty`, `C_ChatInfo.SendChatMessage`, `C_Sound.PlaySound`, `C_Timer.*`, `issecretvalue`, `GetLocale`, `GetTime` y los 14 eventos que usa `Core.lua` |
| Sin comprobar | `GetRealZoneText`, `GetZoneText`, `ZONE_CHANGED_NEW_AREA` (falta la skill `wow-api-map-navigation`), `IsInGroup`, `IsInRaid`, el marco `PlayerModel`, los IDs de hechizo 6991 / 982 / 1515 / 2641 |
| Pueden ser secretos | `UnitName`, `UnitGUID` y el `spellID` de `UNIT_SPELLCAST_SUCCEEDED`: el addon los ignora si llegan secretos |

---

## Hecho

### 2 de noviembre de 2026
- [x] Addon 0.1.0: diario por mascota, 10 estadísticas, Historia, Viajes, 21 logros, retirar/borrar, nota personal, compartir, español e inglés.
- [x] Personalidad, aniversarios y resumen semanal, cada uno con su interruptor.
- [x] Panel de opciones (engranaje), avisos discretos, bienvenida solo la primera vez.
- [x] Logo (`logo/logo.png`), borrador de la ficha (`CURSEFORGE.md`) y zip de la versión.
- [x] Simulación de pruebas fuera del juego (`_luatest`), todas en verde.
- [x] Revisión de código, fallos arreglados:
  - la nota de una mascota se copiaba en otra al cambiar de mascota;
  - una caída podía contarse dos veces si la mascota muerta seguía existiendo;
  - el resumen semanal mezclaba semanas antiguas.
- [x] Revisión contra la API de Forever, arreglados:
  - lealtad con `C_PetInfo.GetPetLoyalty` (puede llegar solo el nombre);
  - compartir con `C_ChatInfo.SendChatMessage`, y si falla se muestra solo en tu chat;
  - sonido con `C_Sound.PlaySound`.
- [x] El zip se hace con `tar.exe` de Windows (el `tar` de Git Bash creaba un `.tar` con nombre `.zip`).
- [x] Ventana nueva con forma de diario abierto: páginas rotas, pestañas de cuero para las mascotas y anillo dorado en el retrato. El arte es de Nano Banana 2 (`art/`, prompts en `docs/ARTE.md`) y se pasa a `Vinculo/Media/*.tga` con `node _luatest/make-art.js`. Títulos en letra Morpheus.
- [x] Revisada la competencia en Forever (Blackthornes Pets, Hunter Field Guide, PetPulse…). Añadido:
  - estado de ánimo en la ficha, "Tiempo contenta" y avisos de tristeza en la historia (`C_PetInfo.GetPetHappiness`);
  - puntos de entrenamiento (`C_PetInfo.GetPetTrainingPoints`);
  - establo: crea la ficha de las guardadas, trae su icono y pregunta por las que ya no están (`C_StableInfo`);
  - botón Exportar y `/vinculo exportar`: la historia en texto para copiar;
  - pestaña Deseos: bestias que quieres domesticar; al domesticar una, se marca sola.

### 3 de noviembre de 2026
- [x] Vídeo de demostración simulado (`docs/video/`).
- [x] Gustos: al ganar un combate se apunta lo que tenías seleccionado (nombre y tipo). La ficha muestra "Presa favorita" y "Su némesis" debajo de la nota, y salen al exportar.
- [x] La mascota habla en **tu** chat (nunca lo envía a otros): al domesticar, subir de nivel, jefe nuevo, resucitar, triste/contenta, zona nueva, comer, rachas y presa favorita. Espera entre frases (30 s a 10 min según el tipo), silencio 20 s al entrar, en combate guarda la frase hasta que acabe, y se desactiva en opciones.

### 3 y 4 de noviembre de 2026 (versión de prueba en MoP y Era)
- [x] Versiones de prueba en el juego: `Vinculo_Mists.toc` (50504) y `Vinculo_Vanilla.toc` (11509). Las APIs que faltan (felicidad, lealtad, puntos de entrenamiento, establo) no dan error: simplemente no salen.
- [x] Aspecto nuevo del libro hecho con piezas de Gemini (`docs/gemini/`): libro, pestañas de cuero, barra de scroll, casillas y cruz de tinta. Script `make-assets.js` que quita el fondo magenta.
- [x] Ficha rehecha: 8 medallones de estadísticas en dos filas, una frase con el resto, tooltip con las 12 cifras, nota al pie. Retrato con modelo 3D guardado para cuando no está invocada.
- [x] Pestañas de la derecha: Historia como línea de tiempo con nodos, Logros como rejilla de medallones con progreso, Viajes agrupados por continente.
- [x] Bestiario (antes Deseos): tus deseos a la izquierda; a la derecha el Códice de 17 familias, que se rellena solo, y los Retos. Botón "+ Añadir mi objetivo".
- [x] Fuentes propias con licencia OFL (`Media/Fonts`): IM Fell English para el texto y Caveat para tus notas. Las cifras sueltas usan la del juego.
- [x] Botón del minimapa con el logo (se quita en ajustes) y ajustes dentro del libro.
- [x] Nuevo vídeo de demostración: `docs/video/vinculo-demo-v2.mp4` (script `make-video-v2.js`).

**Pendiente de ver en el juego:** nombres de familia en español, iconos de familia y de la segunda fila de medallones, bordes del libro, fuente Caveat (es variable), scroll, y todo lo anterior en Forever.

### 4 de noviembre de 2026 (Forever ya instalado)
- [x] Addon copiado a la carpeta de Forever (`_forever_`), además de MoP y Era.
- [x] **Corregida la mascota duplicada** al reconectar: el GUID cambia en cada invocación, ahora se reutiliza la ficha con el mismo nombre y familia.
- [x] Iconos sin borde interior: el icono se dibuja más grande que el hueco del anillo (medallones, logros, Códice, Historia, pestañas, retrato). El recorte con `SetTexCoord` + `SetMask` rompía los iconos en Forever: no usarlo.
- [x] Retrato 2D nativo (`SetPortraitTexture` / `SetPortraitTextureFromCreatureDisplayID`) en lugar del modelo 3D. El `displayID` se sigue guardando con un modelo fuera de pantalla.
- [x] **Bestiario con autocompletar**: sugerencias de bestias (vistas, apuntadas y tabla propia `Data.lua`, 379 de Classic Era, 294 con nombre en español) y de zonas (mapa del juego + pisadas). Tab o clic; la bestia de la tabla rellena su zona. Confirmado en el juego por el jugador.
- [x] La zona de cada bestia sale sola (tabla `Zones.lua`, 39 zonas en inglés y español, sin depender de los IDs del cliente). Confirmado en el juego.
- [x] Iconos del juego (sin borde interior) en lugar de iconos propios: descartado el plan de Gemini (`docs/ARTE-ICONOS.md` queda como referencia).
- [x] Animaciones: fundido al abrir, al cambiar de pestaña o mascota y en el aviso de logro. Pendiente de ver en el juego.
- [x] Botón "Ver mapa" + marcas propias en el mapa del mundo (centro de zona o lugares donde has visto la bestia, grabados al seleccionarla). Confirmado en el juego.
- [x] Tooltip de bestias (lista, familia, habilidad que enseña), aviso al avistar una bestia de la lista, opción sin animaciones. Pendiente de ver todo en Forever.
- [x] Alimentar: insignia junto al retrato con la mejor comida de las bolsas (Forever: CanPetEatItem; MoP/Era: respaldo con Foods.lua).
- [ ] Opcional (descartado por ahora): más de una zona por bestia. Wowhead Classic bloquea las descargas (403); haría falta un volcado de NPC de un emulador.
- [ ] Pendiente: botón "Ver en mapa" (`WorldMapFrame:SetMapID`, sin verificar), datos para MoP/Forever, flechas del teclado en la lista (hecho en 0.1.2, sin ver en el juego). Los 5 uiMapID (1417, 1422, 1423, 1435, 1447) quedaron verificados en Forever el 2026-11-05.
- [x] Versión 0.1.1, `LICENSE` (MIT, con las licencias de las fuentes) y zip para Forever en `dist/Vinculo-0.1.1.zip` (solo `Vinculo.toc`; sin los TOC de MoP y Era). Sin subir: primero probar en Forever.
- [x] Aviso de logro con la plantilla nativa del juego (cartel, animación y apilado) con el logo de Vínculo en el sitio del escudo; respaldo: panel propio. `/vinculo aviso` lo prueba. Confirmado en MoP; falta Forever.
- [x] Arreglada la ficha duplicada al cambiar el idioma del cliente (la familia se compara por clave).
- [x] CurseForge: los zip hechos con `tar` se rechazaron sin motivo; el generado con `docs/build-zip.js` (jszip, comprimido) fue **aprobado** (0.1.1b).
- [ ] Pendiente: página de CurseForge (`CURSEFORGE.md` (raíz)) y capturas.

**Antes de publicar (de la investigación):** `.pkgmeta` y `LICENSE` (con las licencias de las fuentes), quitar `Media/logo.png` y `Media/Ring.tga` del paquete, migración de `VinculoDB`, comprobar la línea `## Interface` de varios clientes, y capturas para la página.

---

## Fase 0 – Lanzamiento de Forever (4 – 10 de noviembre)

Objetivo: que funcione en el juego real sin errores.

### Antes de la prueba
- [ ] Subir `releases/Vinculo-0.1.0.zip` a CurseForge como **Beta** y **Unlisted** (el `.rar` fue rechazado).

### Prueba en el juego (día 4)
Activa antes `/console scriptErrors 1`.
- [ ] `/run print(select(4, GetBuildInfo()))` muestra `16001`, y el addon no sale como "obsoleto".
- [ ] Al entrar con el cazador sale el mensaje de bienvenida (solo la primera vez).
- [ ] `/vinculo` abre la ventana; se puede mover y cerrar con Esc.
- [ ] Al invocar la mascota se crea su ficha con nombre, familia y nivel.
- [ ] Se ve la **lealtad** junto al nivel. Anota si sale un **nombre** o un **número**: el logro "Mejor amigo" solo funciona con número.
- [ ] Se ve el **libro** de fondo (si sale un cuadro verde, la textura no carga) y las pestañas de cuero asoman por la izquierda.
- [ ] El texto se lee bien sobre el pergamino y nada pisa la esquina quemada.
- [ ] El nombre y los títulos (Historia, Logros, Viajes) salen en letra Morpheus; si salen con la letra normal, la ruta `Fonts\MORPHEUS.TTF` no existe en Forever.
- [ ] La rueda del ratón sobre las pestañas pasa mascotas si tienes más de 8.
- [ ] Se ve el **modelo 3D** de la mascota dentro del anillo.
- [ ] Tras unos combates suben "Combates superados" y "En combate".
- [ ] Al dar de comer sube "Comidas" (confirma el ID 6991).
- [ ] Al cambiar de zona aparece en "Viajes".
- [ ] Al matar un jefe de mazmorra se apunta en la Historia (`ENCOUNTER_END`).
- [ ] Si la mascota muere: anota si sigue en pantalla muerta o desaparece. Al revivirla debe contar **una** caída y **una** resurrección.
- [ ] Escribe una nota, pulsa otra mascota de la lista: la nota no debe pasar a la otra.
- [ ] Los iconos de los logros se ven (ninguno sale como cuadro verde o vacío).
- [ ] Junto al nivel sale **Contenta / Normal / Triste**, y "Tiempo contenta" sube. Si no sale nunca, `C_PetInfo.GetPetHappiness` no funciona.
- [ ] "Puntos de entrenamiento" muestra un número (en combate no se actualiza, es normal).
- [ ] En el **establo**: aparecen las mascotas guardadas con su icono, y al sacar una del establo no se duplica su ficha.
- [ ] Si una mascota del diario ya no está en el establo, sale **una** pregunta; con la mascota invocada **no** debe salir.
- [ ] **Exportar** abre la ventana con la historia y Ctrl+C la copia.
- [ ] En **Deseos**: añade "Nombre, zona, nota" con Intro, domestica una bestia con ese nombre y comprueba que se marca.
- [ ] Tras unos combates con objetivo seleccionado, sale "Presa favorita" bajo la nota (a partir de 5). Prueba también en una mazmorra: si ahí no cuenta, el nombre del objetivo llega oculto.
- [ ] La mascota habla en el chat (color de PNJ, "X dice: ..."), no repite frases seguidas y no habla en combate. Pídele a alguien del grupo que confirme que **no** lo ve.
- [ ] El engranaje abre las opciones y cada interruptor funciona (incluido "Tu mascota habla en el chat").
- [ ] "Compartir" envía la ficha al chat del grupo.
- [ ] Ningún error de Lua.

### Publicación
- [ ] Corregir lo que falle en la prueba y publicar **0.1.1**.
- [ ] Hacer 3–4 capturas (Historia, Logros, aviso de logro) y subirlas a la galería de CurseForge.
- [ ] Quitar "Unlisted" cuando 0.1.1 funcione bien.

---

## Fase 1 – Pulido (11 – 30 de noviembre)

Objetivo: que sea cómodo y no tenga fallos. Nada de funciones grandes todavía.

- [ ] Leer los comentarios de CurseForge cada pocos días y apuntar aquí los errores.
- [ ] **"Juntos desde" real:** para mascotas que ya tenías antes de instalar el addon, poner "Diario desde" (la fecha es la de instalación, no la de domesticación).
- [ ] **Modelo 3D sin parpadeo:** recargarlo solo cuando cambia la mascota.
- [ ] **Limpieza:** borrar código sin uso (`ns.safe`, `ns.events`, `pet.lastSeen`, evento `UNIT_HAPPINESS`).
- [ ] Opciones y aviso de logro con el mismo estilo de libro (ahora siguen siendo paneles oscuros).
- [ ] **UI más vistosa** (decidir tras ver el addon en el juego; el arte se pide a Nano Banana 2 con prompts en `docs/ARTE.md`). Ideas:
  - Historia: un icono pequeño por tipo de suceso (jefe, zona, comida, caída, logro) y separadores dibujados por día.
  - Logros: medallas o sellos de lacre; los no conseguidos, como un hueco grabado en el papel.
  - Viajes: un mapa dibujado a mano con las zonas visitadas marcadas.
  - Retrato: icono propio por familia (lobo, felino, oso…) cuando la mascota no está invocada.
  - Animación suave al pasar de pestaña, como si se pasara una página.
  - Aviso de logro como un trozo de pergamino que cae y se desvanece.
- [ ] **Recordar la posición** de la ventana entre sesiones.
- [ ] **Tooltips en las estadísticas** (p. ej. "Combates superados: el combate termina con los dos vivos").
- [ ] Abrir el diario sin comando: entrada en el menú de AddOns del juego (sin botón en el minimapa).
- [ ] Revisar los textos en inglés con la comunidad.
- [ ] Publicar **0.2.0**.

---

## Fase 2 – Más historia (diciembre)

Objetivo: funciones pequeñas que dan vida al diario, sin molestar. Decide el orden según lo que pidan en los comentarios.

- [ ] **Récords personales:** combate más largo, día con más combates, zona favorita, jefe más repetido.
- [ ] **Lápida conmemorativa:** al pasar una mascota al recuerdo, un epitafio que se puede compartir.
- [ ] **Álbum:** botón "Foto" que hace una captura y la enlaza a ese día en la Historia.
- [ ] Más logros (aniversario de 2 años, 10.000 combates, todas las mazmorras de Forever…).
- [ ] Publicar **0.3.0**.

---

## Fase 3 – Comunidad (enero – febrero, solo si los jugadores lo piden)

Es la parte más cara y la más arriesgada con las reglas de Forever.

- [ ] Comprobar si Forever permite mensajes entre addons (`C_ChatInfo.SendAddonMessage`) fuera de combate.
- [ ] **Vitrina de la hermandad:** ver las fichas de las mascotas de los compañeros con Vínculo y una pequeña clasificación.
- [ ] **Mapa de viajes:** resaltar en el mapa del mundo las zonas visitadas juntos.
- [ ] Traducciones de la comunidad (alemán, francés, portugués) con la herramienta de localización de CurseForge.
- [ ] Publicar **1.0.0**.

---

## Herramientas

- [ ] Instalar las skills que faltan, `wow-api-social-chat` y `wow-api-map-navigation`, para comprobar el chat y las zonas.

---

## Siempre (cada parche de Forever)

- [ ] Leer las notas del parche buscando cambios en addons o mascotas.
- [ ] Actualizar `## Interface` en `Vinculo.toc` y la tabla de "Objetivo técnico" si cambia la versión.
- [ ] Volver a comprobar las APIs con `node .claude/skills/wow-api-index/scripts/query.mjs forever <nombre>`.
- [ ] Pasar las pruebas: `node _luatest/run.js`.
- [ ] Probar en el juego lo básico de la Fase 0.

---

## Cómo publicar una versión

1. Cambia `## Version` en `Vinculo/Vinculo.toc` y la versión al principio de este archivo.
2. Pasa las pruebas: `node _luatest/run.js` (debe acabar en "TODAS LAS PRUEBAS PASAN").
3. Crea el zip desde la carpeta del proyecto, en PowerShell (siempre `.zip`, nunca `.rar`):
   `C:\Windows\System32\tar.exe -a -c -f releases\Vinculo-X.Y.Z.zip Vinculo`
   El `tar` de Git Bash no sirve: crea un `.tar` aunque el nombre acabe en `.zip`.
4. Súbelo en CurseForge → Files → Upload file, versión **WoW Forever**, y escribe qué ha cambiado.
5. Marca aquí lo terminado y apúntalo en "Hecho" con la fecha.

---

## Inspiración de otros addons (2 de noviembre de 2026)

Ideas sacadas de addons existentes, para adaptar y no copiar.

**Competencia directa en Forever:** *Hunter Field Guide* tiene "My Companions", donde apunta las domas, y *PetPulse Forever* muestra la felicidad y la experiencia de la mascota. Vínculo se diferencia por la parte de **historia y recuerdos**, y eso hay que cuidarlo.

Visual:
- Modelo 3D de la mascota más grande en la página, con animación al abrir (*Storyline*).
- El suceso destacado o el epitafio se escriben letra a letra, y un clic lo completa (*Storyline*, *Dark Modal UI*).
- 2 o 3 pieles para el libro: cuero, pergamino viejo y una de luto para las mascotas retiradas (*DialogueUI*).
- En Viajes, progreso del tipo "zonas visitadas 12/40" con una barra por continente (*PetTracker*).
- Logros con filtros: conseguidos y pendientes (*Krowi's Achievement Filter*).
- Mapa con puntos donde la domesticaste y donde cayó (*Hunter Field Guide*).

Funciones:
- "Certificado de adopción": lugar, fecha y primera foto de la doma.
- Rasgos con deslizadores que elige el jugador, por ejemplo Valiente–Cauteloso (*MyRolePlay*, *SimpleRP*).
- Lista de deseos: bestias que quieres domar, con notas.
- Comparar dos mascotas lado a lado.
- Tutorial breve la primera vez que se abre (*Krowi*).
- Enlace con *Total RP 3*, que ya permite perfiles de mascota.

Evitar:
- Ventanas que tapan la acción o que pesan.
- Tooltips enormes.
- Reemplazar marcos de Blizzard, porque da problemas de taint.
- Romperse en combate: mejor mostrar "no disponible".
- Animaciones que no se pueden desactivar: cada efecto nuevo lleva su interruptor en las opciones.

---

## Ideas aparcadas

Cosas que se pensaron pero no se harán por ahora:

- Botón en el minimapa: descartado para mantener la interfaz limpia.
- Contar enemigos muertos: Forever no deja leer el registro de combate.
- Cualquier aviso que diga qué hacer en combate: va contra las normas de addons de Forever.
