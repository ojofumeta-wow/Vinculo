# Arte con Nano Banana 2

Prompts para generar las texturas del diario. Pega cada uno en Gemini (Nano Banana 2), descarga la imagen en PNG y guárdala en `art/` con el nombre indicado. Luego se recorta, se pasa a tamaño potencia de 2 y a `.tga` para WoW.

Reglas para todas:
- Sin texto, letras, runas legibles, iconos ni botones: el addon pone todo eso encima.
- Vista totalmente frontal y plana, sin perspectiva, sin sombra de mesa ni fondo de escena.
- Si pide transparencia y no la da, que use fondo **magenta puro #FF00FF** para recortarlo.

---

## 1. Libro abierto → `art/book.png`

Formato 2:1 (horizontal).

```
A flat, perfectly top-down orthographic view of an open leather-bound hunter's journal, filling the whole image edge to edge, 2:1 aspect ratio. Hand-painted fantasy game UI texture style, warm and slightly stylized, like classic MMORPG interface art, but an original design.

The cover is dark brown worn leather with a thin stitched gold-thread border and small brass corner caps shaped like stylized paw prints. Two aged parchment pages, cream to light tan, with darker burnt-tan vignetting toward the edges, subtle paper fibers, a faint tea-cup ring stain on the right page and a small ink blot on the left page.

The outer edges of both pages are torn and ragged, with small rips and missing bits. The bottom-right corner of the right page is torn off and slightly scorched black-brown. A soft darker crease runs down the center spine. A narrow braided leather strap hangs down the spine as a bookmark, ending in a small round brass charm below the book.

Both pages are completely blank: no text, no writing, no letters, no symbols, no illustrations. No hands, no table, no background scene: the book fills the frame. Even, soft lighting, no strong shadows.
```

## 2. Pestaña de cuero para cada mascota → `art/tab.png`

Formato 1:1.

```
A single small leather bookmark tab for a fantasy journal, seen perfectly front-on and flat, horizontal, rounded on the left end and cut straight on the right end, with a round empty socket on the left made of a thin brass ring (the socket center is plain dark brown, empty). Dark brown worn leather with fine gold stitching along the edge. Hand-painted fantasy game UI texture style. Centered on a pure magenta #FF00FF background, no shadow, no text, no icon inside the socket.
```

## 3. Anillo del retrato → `art/ring.png`

Formato 1:1.

```
A single ornate round brass portrait frame ring for a fantasy game interface, seen perfectly front-on and flat, slightly worn gold metal with small engraved leaf and claw motifs, the inside of the ring is completely empty and filled with pure magenta #FF00FF, the outside background is also pure magenta #FF00FF. Hand-painted fantasy game UI texture style, no text, no shadow.
```

## 4. Logo del addon → `art/logo.png`

Formato 1:1. Es el icono de CurseForge: se ve muy pequeño (unos 64 px), así que tiene que leerse con una forma simple y fuerte.

```
A square emblem icon for a fantasy game addon about a hunter and their animal companion. A round medallion: dark brown worn leather center with fine gold stitching around the edge, framed by a slightly worn engraved brass ring with small leaf motifs. In the center, a bold golden paw print, and a hunter's arrow crossing diagonally behind it. Bold, clear silhouette that stays readable when shrunk to 64 pixels. Hand-painted fantasy game UI style, warm gold and brown palette matching an old leather journal. The medallion fills about 90% of the image, centered, on a pure magenta #FF00FF background. No text, no letters, no shadow, front-facing and flat.
```

---

Si una imagen sale con texto o en perspectiva, repite añadiendo al final: `Strictly no text and strictly flat top-down view.`
