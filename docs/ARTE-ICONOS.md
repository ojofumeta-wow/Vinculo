# Iconos propios con Gemini (5 láminas, 45 iconos)

Sustituyen a los iconos del juego, que traen un borde interior que se ve dentro del círculo.
El addon recorta cada icono en círculo y le pone el anillo de latón encima, así que **el dibujo debe llenar su casilla de borde a borde, sin marco, sin borde y sin esquinas vacías**.

Cómo hacerlo: pega el estilo común + el contenido de cada lámina en Gemini (Nano Banana 2), 1:1. Guarda cada PNG en `docs/gemini/iconos/` como `A.png`, `B.png`… Si una lámina sale torcida o mezcla casillas, repítela o pídela de 2x2 en vez de 3x3.

## Estilo común (ponlo al principio de cada prompt)

```
A 3x3 grid of 9 separate square game icons on a pure magenta #FF00FF background, with a thick magenta gutter between them so they never touch. Each icon is a fully painted SQUARE that fills its cell edge to edge: the artwork extends to all four sides and corners of its square, with NO border, NO frame, NO ring, NO bevel, NO rounded corners and NO empty corners. The background of every icon is the SAME flat dark sepia-brown ink wash (about #3a2a1c) with no lighter glow or spotlight behind the subject, no paper texture, no stains, no splatters, no ragged edges. The subject is bright and clearly lit, centered, and fits entirely inside the central circle that touches the middle of each square's sides (about 70% of the width), with nothing important near the corners. Style: antique woodcut and copperplate engraving, drawn with bold black-brown ink lines and visible cross-hatching and stippling for shading, slightly irregular hand-cut line quality, like a page from a 17th-century naturalist's bestiary. Only a limited palette: cream-ivory ink for the subject's light parts, sepia for shading, and ONE muted accent colour per icon (rust red, moss green or old gold) applied flat like a printed spot colour. NOT realistic, NOT a photo, NOT soft or airy, NOT a cartoon, no gradients on the subject, no glossy highlights, no glow or halo behind the subject. Animals in strong side profile or three-quarter view with a characterful, wild expression. Identical style, line weight, lighting and detail level in every icon. Absolutely no text, letters, numbers, runes, logos, faction crests, circles or frames inside the icon, no watermark.
```

## Estilo alternativo "WoW pintado a mano" (prueba con la lámina B)

Cambia solo la parte de "Style:" del bloque común por esto (el fondo oscuro y las reglas de encaje se quedan):

```
Style: classic early-2000s MMORPG hand-painted icon art, chunky and stylized: bold simple shapes, strong dark outline, exaggerated features, high contrast with a bright rim light on one side, saturated but earthy colours, painterly brush strokes with minimal fine detail so it stays readable when shrunk to 40 pixels. Each animal is a recognizable fierce silhouette head in profile or three-quarter view, snarling, with big expressive eyes. NOT realistic, NOT an engraving, NOT soft, NOT photo-like, no halo or glow behind it, no pixel art, no low-poly 3D.
```

## Lámina A → `A.png` (medallones y logros de la ficha)

```
Icons, left to right, top to bottom:
1. Victories: a crossed hunting sword and a wolf claw.
2. Bosses: a horned dragon head, front view.
3. Time together: an open brass pocket watch.
4. Streak: a laurel wreath around a small flame.
5. Zones: a folded old map with a red X.
6. Dungeons: an iron-barred stone cave gate.
7. Meals: a roasted meat haunch on the bone.
8. Falls: a bone-white skull.
9. Taming: a coiled rope lasso over a paw print.
Leave no extra icons.
```

## Lámina B → `B.png` (familias 1)

```
Icons, left to right, top to bottom, each the head of the animal in side profile or three-quarter view, wild and characterful (never a calm frontal portrait):
1. Bat  2. Bear  3. Boar  4. Vulture (carrion bird)  5. Wildcat (cat)  6. Crab  7. Crocolisk (crocodile)  8. Gorilla  9. Hyena
```

## Lámina C → `C.png` (familias 2)

```
Icons, left to right, top to bottom, each the head or full body of the animal:
1. Owl  2. Raptor (small dinosaur head)  3. Scorpid (scorpion)  4. Spider  5. Tallstrider (long-necked ostrich-like bird)  6. Turtle  7. Wind serpent (flying snake-dragon with small wings)  8. Wolf  9. A generic beast paw print with a question mark-shaped curl (unknown family)
```

## Lámina D → `D.png` (logros de jefes, viajes y rachas)

```
Icons, left to right, top to bottom:
1. Five thousand victories: a hunter's horn crossed with a spear, with a paw print.
2. Win streak: a radiant winged star.
3. Maximum loyalty: a hand clasping a paw, with a small heart.
4. First boss: a small green whelp dragon head.
5. Ten bosses: a black dragon head.
6. Fifty bosses: a red dragon head wearing a tiny crown.
7. Five zones: a small map with one pin.
8. Twenty zones: a large unrolled map with many pins.
9. Forty zones: a brass spyglass over a coastline.
```

## Lámina E → `E.png` (tiempo, aniversarios y diario)

```
Icons, left to right, top to bottom:
1. Ten hours together: a silver pocket watch.
2. One hundred hours together: an ornate golden pocket watch with small gems.
3. One hundred meals: a roast drumstick and a bone on a plate.
4. Resurrection: a paw print with a soft green glow and a feather.
5. One month together: a folded note sealed with red wax.
6. One year together: a small gift box tied with a ribbon.
7. Wish: a rolled scroll tied with a cord.
8. Level up: an upward arrow made of a feather, with a small star.
9. Renamed: a quill in an ink pot.
```

## Después de recibirlas
Me pasas las 5 imágenes y yo: las recorto en 45 iconos de 64x64, las convierto a `.tga`, las meto en `Media/Icons/` y cambio el código para usarlas (medallones, logros, familias, Historia y Códice). Los iconos del juego quedan solo de reserva.
