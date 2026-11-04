// Vídeo de demostración de Vínculo v0.1 (simulación con el arte y las fuentes reales del addon).
// Uso: node make-video-v2.js [out.mp4] | node make-video-v2.js --frame segundos...
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");
const { spawn } = require("child_process");
const ROOT = "C:/Users/Javier/Desktop/WoW Addons/Vinculo";
const { Resvg } = require(path.join(ROOT, "_luatest/node_modules/@resvg/resvg-js"));
const FFMPEG = process.env.FFMPEG || require("ffmpeg-static");

const W = 1280, H = 720, FPS = 30, DUR = 45;

// ---------- texturas ----------
function readTGA(file, cropW, cropH) {
    const b = fs.readFileSync(file);
    const w = b.readUInt16LE(12), h = b.readUInt16LE(14);
    const cw = cropW || w, ch = cropH || h;
    const px = Buffer.alloc(cw * ch * 4);
    for (let y = 0; y < ch; y++) for (let x = 0; x < cw; x++) {
        const s = 18 + ((h - 1 - y) * w + x) * 4, d = (y * cw + x) * 4;
        px[d] = b[s + 2]; px[d + 1] = b[s + 1]; px[d + 2] = b[s]; px[d + 3] = b[s + 3];
    }
    return "data:image/png;base64," + png(cw, ch, px).toString("base64");
}
function png(w, h, px) {
    const raw = Buffer.alloc((w * 4 + 1) * h);
    for (let y = 0; y < h; y++) px.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4);
    const chunk = (t, d) => {
        const len = Buffer.alloc(4); len.writeUInt32BE(d.length);
        const td = Buffer.concat([Buffer.from(t), d]);
        const crc = Buffer.alloc(4); crc.writeUInt32BE(zlib.crc32(td) >>> 0);
        return Buffer.concat([len, td, crc]);
    };
    const ihdr = Buffer.alloc(13);
    ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 6;
    return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
        chunk("IHDR", ihdr), chunk("IDAT", zlib.deflateSync(raw)), chunk("IEND", Buffer.alloc(0))]);
}
const MEDIA = path.join(ROOT, "Vinculo/Media");
const IMG = {
    book: readTGA(path.join(MEDIA, "Book.tga")),
    tab: readTGA(path.join(MEDIA, "Tab.tga"), 512, 155),
    ring128: readTGA(path.join(MEDIA, "Ring128.tga")),
    ring64: readTGA(path.join(MEDIA, "Ring64.tga")),
    checkOn: readTGA(path.join(MEDIA, "CheckOn.tga")),
    checkOff: readTGA(path.join(MEDIA, "CheckOff.tga")),
    cross: readTGA(path.join(MEDIA, "Cross.tga")),
    thumb: readTGA(path.join(MEDIA, "ScrollThumb.tga"), 48, 108),
    logo: "data:image/png;base64," + fs.readFileSync(path.join(MEDIA, "logo.png")).toString("base64"),
    icon: readTGA(path.join(MEDIA, "Icon.tga")),
};

// ---------- utilidades ----------
const clamp01 = (v) => Math.max(0, Math.min(1, v));
const ease = (v) => { v = clamp01(v); return v < 0.5 ? 2 * v * v : 1 - Math.pow(-2 * v + 2, 2) / 2; };
const prog = (t, a, b) => ease((t - a) / (b - a));
const lerp = (a, b, k) => a + (b - a) * k;
const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const TITLE = "Palatino Linotype", BODY = "IM FELL English, Georgia", NOTE = "Caveat, Georgia", NUM = "Georgia", SYM = "Segoe UI Symbol";
const INK = "#3d240d", INK_SOFT = "#6b4a24", INK_RED = "#8a290d", HEAD = "#5a1e08", DIM = "#7a6448", GREEN = "#2f5a12";

function text(x, y, s, o = {}) {
    return `<text x="${x}" y="${y}" font-family="${o.font || BODY}" font-size="${o.size || 12}" fill="${o.fill || INK}"` +
        `${o.anchor ? ` text-anchor="${o.anchor}"` : ""}${o.weight ? ` font-weight="${o.weight}"` : ""}` +
        `${o.italic ? ` font-style="italic"` : ""}${o.opacity != null ? ` opacity="${o.opacity}"` : ""}` +
        `${o.stroke ? ` stroke="${o.stroke}" stroke-width="${o.sw || 3}" paint-order="stroke"` : ""}>${esc(s)}</text>`;
}
function spans(x, y, parts, o = {}) {
    return `<text x="${x}" y="${y}" font-family="${o.font || BODY}" font-size="${o.size || 12}">` +
        parts.map(([s, c]) => `<tspan fill="${c || INK}">${esc(s)}</tspan>`).join("") + `</text>`;
}
function wrap(s, max) {
    const out = []; let line = "";
    for (const w of s.split(" ")) {
        if ((line + " " + w).trim().length > max) { out.push(line); line = w; } else line = (line + " " + w).trim();
    }
    if (line) out.push(line);
    return out;
}
const PAW = (cx, cy, r, fill) => `<g fill="${fill}">
<ellipse cx="${cx}" cy="${cy + r * 0.35}" rx="${r * 0.55}" ry="${r * 0.45}"/>
<ellipse cx="${cx - r * 0.62}" cy="${cy - r * 0.25}" rx="${r * 0.2}" ry="${r * 0.27}"/>
<ellipse cx="${cx - r * 0.22}" cy="${cy - r * 0.58}" rx="${r * 0.2}" ry="${r * 0.27}"/>
<ellipse cx="${cx + r * 0.22}" cy="${cy - r * 0.58}" rx="${r * 0.2}" ry="${r * 0.27}"/>
<ellipse cx="${cx + r * 0.62}" cy="${cy - r * 0.25}" rx="${r * 0.2}" ry="${r * 0.27}"/></g>`;

// Medallón: icono redondo (disco de color + símbolo) bajo un anillo de latón
function medal(cx, cy, size, color, glyph, o = {}) {
    const r = size * 0.3, dim = o.dim != null ? o.dim : 1;
    return `<g opacity="${o.opacity != null ? o.opacity : 1}">
<circle cx="${cx}" cy="${cy}" r="${r + 1.5}" fill="${color}" opacity="${dim}"/>
<circle cx="${cx}" cy="${cy}" r="${r + 1.5}" fill="#000" opacity="${o.gray ? 0.18 : 0}"/>
${glyph ? text(cx, cy + size * 0.15, glyph, { font: SYM, size: size * 0.42, fill: "#fff", anchor: "middle", opacity: 0.9 * dim }) : ""}
<image href="${IMG.ring64}" x="${cx - size / 2}" y="${cy - size / 2}" width="${size}" height="${size}" ${o.gray ? 'style="filter:grayscale(1)"' : ""} opacity="${o.ringOpacity != null ? o.ringOpacity : 1}"/>
</g>`;
}

// ---------- datos de ejemplo ----------
const PETS = [
    {
        name: "Garra", family: "Lobo", level: 34, tint: "#c9b48a",
        since: "Juntos desde el 12/10/2026 · Os conocisteis en Bosque de Elwynn", tag: [["Contigo ahora", GREEN], ["  ·  ", DIM], ["Valiente", INK_RED]],
        note: "Le encanta perseguir conejos en Elwynn.",
        medals: [["Combates", "412", "#9c3a22", "⚔"], ["Jefes", "9", "#7a2a6a", "☠"], ["Juntos", "30h", "#a8801e", "⌛"], ["Racha", "131", "#c1581a", "★"],
        ["Zonas", "14", "#3a6a8a", "⚑"], ["Mazmorras", "3", "#4a4a7a", "♜"], ["Comidas", "58", "#a85a3a", "♨"], ["Caídas", "6", "#6a6a6a", "✝"]],
        story: ["Habéis pasado 7 h 12 min en combate.", "Ha vuelto a levantarse 5 veces."],
        likes: "Presa favorita: Conejo de campo (62)",
        timeline: [
            ["01/11/2026", "Logro: Compañeros de caza", true, "★"], ["28/10/2026", "Nueva lealtad: Fiel.", false, "♥"],
            ["22/10/2026", "Logro: Cazadores de gigantes", true, "★"], ["22/10/2026", "Derrotasteis juntos a Edwin VanCleef.", true, "☠"],
            ["19/10/2026", "Garra alcanzó el nivel 20.", true, "▲"], ["15/10/2026", "Primera vez juntos en Páramos de Poniente.", false, "⚑"],
            ["12/10/2026", "Domesticaste a Garra en Bosque de Elwynn.", true, "♥"],
        ],
    },
    {
        name: "Sombra", family: "Felino", level: 28, tint: "#9aa0b4",
        since: "Juntos desde el 20/10/2026 · Os conocisteis en Bosque del Ocaso", tag: [["En el establo", "#7a6a50"], ["  ·  ", DIM], ["Sigilosa", INK_RED]],
        note: "Silenciosa. Odia la lluvia.",
        medals: [["Combates", "187", "#9c3a22", "⚔"], ["Jefes", "2", "#7a2a6a", "☠"], ["Juntos", "14h", "#a8801e", "⌛"], ["Racha", "64", "#c1581a", "★"],
        ["Zonas", "6", "#3a6a8a", "⚑"], ["Mazmorras", "1", "#4a4a7a", "♜"], ["Comidas", "21", "#a85a3a", "♨"], ["Caídas", "3", "#6a6a6a", "✝"]],
        story: ["Habéis pasado 3 h 05 min en combate.", "Ha vuelto a levantarse 3 veces."],
        likes: "Caza sobre todo: Bestia",
        timeline: [
            ["30/10/2026", "Sombra vuelve a estar contenta.", false, "♥"], ["27/10/2026", "Primera vez juntos en Montañas Crestagrana.", false, "⚑"],
            ["24/10/2026", "Sombra alcanzó el nivel 25.", false, "▲"], ["20/10/2026", "Domesticaste a Sombra en Bosque del Ocaso.", true, "♥"],
        ],
    },
    { name: "Colmillo", family: "Jabalí", level: 12, tint: "#b08a6a" },
];
const ALL_STATS = [["Combates superados", "412"], ["Jefes", "9"], ["Zonas", "14"], ["Mazmorras", "3"], ["Mejor racha", "131"], ["Tiempo juntos", "1d 6h"],
    ["En combate", "7h 12m"], ["Comidas", "58"], ["Caídas", "6"], ["Resurrecciones", "5"], ["Tiempo contenta", "82 %"], ["Puntos de entrenamiento", "40 libres de 220"]];
const ACH = [
    ["Primera presa", 1], ["Compañeros de caza", 1], ["Manada de dos", 0], ["Leyenda de la espesura", 0], ["Intocable", 0], ["Creciendo", 1],
    ["Veterano", 1], ["Madurez", 0], ["Cazador de gigantes", 1], ["Cazador de dragones", 0], ["Señor de la caza", 0], ["Exploradores", 1],
    ["Trotamundos", 0], ["Viajeros", 0], ["Inseparables", 1], ["Compañeros de fortuna", 0], ["Buena mesa", 1], ["Sin rendirse", 1],
    ["Un mes juntos", 1], ["Un año juntos", 0], ["Lealtad máxima", 0],
];
const ZONES = [["Bosque de Elwynn", "12/10/2026"], ["Páramos de Poniente", "15/10/2026"], ["Bosque del Ocaso", "17/10/2026"], ["Montañas Crestagrana", "20/10/2026"], ["Los Humedales", "26/10/2026"]];
const FAMILIES = [["Murciélago", 0], ["Oso", 1], ["Jabalí", 1], ["Carroñero", 0], ["Gato", 1], ["Cangrejo", 0], ["Crocolisco", 0], ["Gorila", 0], ["Hiena", 0],
    ["Búho", 0], ["Raptor", 0], ["Escórpido", 0], ["Araña", 2], ["Zancaalta", 0], ["Tortuga", 0], ["Serpiente alada", 0], ["Lobo", 1]];
const FAMILY_COLORS = ["#6a5a7a", "#7a5030", "#8a5a3a", "#5a4a3a", "#a88a50", "#b0503a", "#4a7a3a", "#4a4a4a", "#8a7a50", "#6a6a8a", "#7a3a3a", "#5a3a2a", "#3a3a3a", "#8a6a4a", "#3a7a5a", "#5a8a9a", "#8a8a8a"];
const RETOS = [["Doma 5 familias distintas", 4, 5], ["Ten 3 mascotas en el diario", 3, 3], ["Derrota a 100 criaturas", 100, 100], ["Derrota a 5 tipos de criatura", 3, 5], ["Doma las familias clásicas", 4, 17]];
const WISH = "Rey Bangalash, Vega de Tuercespina, tigre raro";
const OPTIONS = ["Avisar al conseguir logros", "Avisos discretos (solo en el chat)", "Sonido en los avisos", "Resumen semanal al entrar",
    "Recordar aniversarios", "Mostrar la personalidad", "Tu mascota habla en el chat (solo tú lo ves)", "Botón en el minimapa"];

// ---------- guion (segundos) ----------
const BS = 1.2, BX = 170, BY = 58;
const bx = (x) => BX + x * BS, by = (y) => BY + y * BS;
const LEFT_X = 75, RIGHT_X = 484, PAGE_W = 330;
const TAB_W = 150, TAB_H = 45, TAB_STEP = 48, TAB_OUT = 60;
const tabLabels = [["story", "Historia"], ["achievements", "Logros"], ["travels", "Viajes"]];
function tabX(i) { let x = RIGHT_X; for (let k = 0; k < i; k++) x += tabLabels[k][1].length * 10.4 + 16; return x; }
const P = (x, y) => [bx(x), by(y)];
const MINI = [1088, 166];
const wishTabY = 32 + 3 * TAB_STEP + 22;
const MOUSE = [
    [3.0, 760, 430], [4.8, ...MINI], [6.2, ...MINI],
    [7.2, ...P(165, 156)], [8.2, ...P(165, 156)], [9.4, ...P(330, 240)], [10.8, ...P(330, 240)],
    [11.6, ...P(-30, 24 + TAB_STEP + 22)], [13.0, ...P(-30, 24 + TAB_STEP + 22)],
    [13.7, ...P(-30, 24 + 22)], [14.2, ...P(-30, 24 + 22)],
    [15.0, ...P(tabX(1) + 25, 46)], [16.4, ...P(tabX(1) + 25, 46)],
    [17.4, ...P(RIGHT_X + 2 * 52 + 28, 74 + 40 + 22)], [19.2, ...P(RIGHT_X + 2 * 52 + 28, 74 + 40 + 22)],
    [19.9, ...P(tabX(2) + 25, 46)], [22.2, ...P(tabX(2) + 25, 46)],
    [22.8, ...P(-30, wishTabY)], [23.8, ...P(-30, wishTabY)],
    [24.6, ...P(LEFT_X + 120, 112)], [28.2, ...P(LEFT_X + 120, 112)],
    [29.0, ...P(LEFT_X + 60, 138)], [30.0, ...P(LEFT_X + 60, 138)],
    [30.9, ...P(RIGHT_X + 4 * 52 + 28, 74 + 26 + 44 + 22)], [32.6, ...P(RIGHT_X + 4 * 52 + 28, 74 + 26 + 44 + 22)],
    [33.4, ...P(786, 42)], [34.2, ...P(786, 42)],
    [35.2, ...P(RIGHT_X + 11, 74 + 4 + 6 * 26 + 11)], [36.8, ...P(RIGHT_X + 11, 74 + 4 + 6 * 26 + 11)],
    [37.8, ...P(808, 42)], [38.4, ...P(808, 42)], [40.0, 760, 450],
];
const CLICKS = [5.0, 12.0, 13.9, 15.2, 19.7, 23.0, 24.7, 28.3, 33.8, 36.2, 38.2];
function mouseAt(t) {
    if (t <= MOUSE[0][0]) return MOUSE[0].slice(1);
    for (let i = 1; i < MOUSE.length; i++) if (t <= MOUSE[i][0]) {
        const [t0, x0, y0] = MOUSE[i - 1], [t1, x1, y1] = MOUSE[i];
        const k = ease((t - t0) / (t1 - t0));
        return [lerp(x0, x1, k), lerp(y0, y1, k)];
    }
    return MOUSE[MOUSE.length - 1].slice(1);
}
function state(t) {
    return {
        book: t >= 5.0 && t < 38.6,
        view: t >= 23.0 && t < 33.8 ? "wishes" : "pet",
        settings: t >= 33.8 && t < 38.2,
        pet: t >= 12.0 && t < 13.9 ? 1 : 0,
        tab: t < 15.2 ? "story" : t < 19.7 ? "achievements" : "travels",
        hoverPet: t >= 11.6 && t < 13.0 ? 1 : -1,
        statTip: t >= 8.4 && t < 11.0,
        achTip: t >= 17.6 && t < 19.4,
        codexTip: t >= 31.0 && t < 32.8,
        wishTyped: t < 24.8 ? -1 : WISH.slice(0, Math.floor(clamp01((t - 25.0) / 2.6) * WISH.length)),
        wishAdded: t >= 28.3,
        optionOff: t >= 36.2,
    };
}
const CAPTIONS = [
    [3.2, 5.0, "El botón del minimapa abre el diario"],
    [6.4, 11.0, "Cada mascota tiene su ficha: medallones con lo esencial y una frase con el resto"],
    [11.0, 15.0, "Las pestañas de cuero son tus mascotas, también las del establo"],
    [15.0, 19.6, "Logros propios para cada compañera, con su progreso"],
    [19.6, 22.8, "Zonas por continente, mazmorras y jefes que habéis visto juntos"],
    [22.8, 28.0, "El Bestiario: apunta las bestias que quieres domesticar"],
    [28.0, 33.4, "El Códice se rellena solo con tus mascotas y las bestias que derrotáis, y los retos se marcan solos"],
    [33.4, 37.6, "Ajustes dentro del libro: avisos, sonido, botón del minimapa…"],
    [38.9, 42.0, "Tu mascota comenta cosas en el chat, solo lo ves tú"],
];

// ---------- dibujo ----------
function background(t) {
    const drift = t * 6;
    return `<defs>
<radialGradient id="bg" cx="50%" cy="45%" r="75%"><stop offset="0" stop-color="#2c3a2a"/><stop offset="0.6" stop-color="#16201a"/><stop offset="1" stop-color="#070a08"/></radialGradient>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.55"/></linearGradient>
<clipPath id="content"><rect x="${RIGHT_X - 4}" y="72" width="${PAGE_W - 6}" height="216"/></clipPath>
</defs>
<rect width="${W}" height="${H}" fill="url(#bg)"/>
<g opacity="0.22" fill="#0c120d">
${[0, 1, 2, 3, 4, 5, 6, 7, 8].map((i) => { const x = (i * 170 + drift) % (W + 200) - 100, h = 260 + (i * 53) % 140;
        return `<path d="M${x} ${H} L${x + 60} ${H - h} L${x + 120} ${H} Z"/>`; }).join("")}
</g>
<rect width="${W}" height="${H}" fill="url(#sky)"/>`;
}

function minimap(t) {
    if (t < 3.2 || t > 6.6) return "";
    const a = prog(t, 3.2, 3.7) * (1 - prog(t, 5.8, 6.6));
    const [cx, cy, r] = [1150, 130, 74];
    const hover = t >= 4.6 && t < 5.4;
    return `<g opacity="${a}">
<circle cx="${cx}" cy="${cy}" r="${r + 6}" fill="#3a2a14"/><circle cx="${cx}" cy="${cy}" r="${r}" fill="#46633a"/>
<path d="M${cx - 50} ${cy + 10} q30 -30 60 -5 t45 -12" stroke="#7a9a5a" stroke-width="10" fill="none" opacity="0.6"/>
<circle cx="${cx + 8}" cy="${cy - 4}" r="4" fill="#ffd100"/>
<g transform="translate(${MINI[0]} ${MINI[1]})"><circle r="${hover ? 22 : 20}" fill="#0b0805" stroke="#c9a24a" stroke-width="2"/>
<image href="${IMG.icon}" x="-17" y="-17" width="34" height="34"/></g>
</g>`;
}

function petTab(i, pet, selected, hover) {
    const x = -(selected ? TAB_OUT + 10 : TAB_OUT), y = 24 + i * TAB_STEP;
    const ix = x + TAB_W * 0.145, iy = y + TAB_H / 2 - 2, r = TAB_H * 0.25;
    return `<g>
<circle cx="${ix}" cy="${iy}" r="${r}" fill="#20140a"/>${PAW(ix, iy + 1, r * 0.85, pet.tint)}
<image href="${IMG.tab}" x="${x}" y="${y}" width="${TAB_W}" height="${TAB_H}" preserveAspectRatio="none"/>
${selected ? `<circle cx="${ix}" cy="${iy}" r="${r + 3}" fill="none" stroke="#ffd36a" stroke-width="2" opacity="0.9"/>` : ""}
${hover ? `<circle cx="${ix}" cy="${iy}" r="${r + 1}" fill="#fff" opacity="0.18"/>` : ""}
</g>`;
}
function wishMarker(selected) {
    const x = -(selected ? TAB_OUT + 10 : TAB_OUT), y = 32 + 3 * TAB_STEP;
    const ix = x + TAB_W * 0.145, iy = y + TAB_H / 2 - 2, r = TAB_H * 0.25;
    return `<g><circle cx="${ix}" cy="${iy}" r="${r}" fill="#d8c08a"/>
<path d="M${ix - 6} ${iy - 6} h12 v12 h-12 z" fill="#f3e3bd" stroke="#8a6a32" stroke-width="1"/>
<path d="M${ix - 4} ${iy - 3} h8 M${ix - 4} ${iy} h8 M${ix - 4} ${iy + 3} h5" stroke="#8a6a32" stroke-width="0.8"/>
<image href="${IMG.tab}" x="${x}" y="${y}" width="${TAB_W}" height="${TAB_H}" preserveAspectRatio="none"/>
${selected ? `<circle cx="${ix}" cy="${iy}" r="${r + 3}" fill="none" stroke="#ffd36a" stroke-width="2" opacity="0.9"/>` : ""}</g>`;
}

function leftPagePet(pet) {
    let s = "";
    s += `<circle cx="107.5" cy="72.5" r="25" fill="#1a110a"/>${PAW(107.5, 74, 20, pet.tint)}`;
    s += `<image href="${IMG.ring128}" x="69" y="34" width="77" height="77"/>`;
    s += text(158, 62, pet.name, { font: TITLE, size: 26, fill: INK, weight: "bold" });
    s += text(158, 80, `${pet.family} · Nivel ${pet.level}`, { font: NUM, size: 11, fill: INK });
    wrap(pet.since, 40).forEach((l, i) => s += text(158, 94 + i * 12, l, { font: NUM, size: 9, fill: DIM }));
    s += spans(158, 124, pet.tag, { size: 11 });
    pet.medals.forEach(([label, val, color, glyph], i) => {
        const cx = LEFT_X + (PAGE_W / 4) * ((i % 4) + 0.5), cy = 150 + Math.floor(i / 4) * 84;
        s += medal(cx, cy, 46, color, glyph);
        s += text(cx, cy + 42, val, { font: NUM, size: 15, fill: INK, anchor: "middle", weight: "bold" });
        s += text(cx, cy + 56, label, { size: 11, fill: INK_SOFT, anchor: "middle" });
    });
    pet.story.forEach((l, i) => s += text(LEFT_X + 4, 314 + i * 18, l, { size: 13, fill: INK }));
    s += text(LEFT_X + 4, 358, pet.likes, { size: 11, fill: INK_SOFT });
    s += text(LEFT_X + 2, 376, pet.note, { font: NOTE, size: 16, fill: INK });
    s += `<line x1="${LEFT_X}" y1="383" x2="${LEFT_X + PAGE_W}" y2="383" stroke="${INK_SOFT}" opacity="0.5"/>`;
    return s;
}

function leftPageWishes(t, st) {
    let s = "";
    s += text(158, 62, "Bestiario", { font: TITLE, size: 26, fill: INK, weight: "bold" });
    s += text(158, 80, st.wishAdded ? "1 de 3 domesticadas" : "1 de 2 domesticadas", { font: NUM, size: 11, fill: INK });
    const typing = st.wishTyped !== -1 && !st.wishAdded;
    const v = typing ? st.wishTyped + (Math.floor(t * 3) % 2 ? "|" : "") : "";
    s += text(LEFT_X + 2, 118, v || "Bestia, zona, nota (Intro para añadir)", { font: NOTE, size: 15, fill: v ? INK : DIM });
    s += `<line x1="${LEFT_X}" y1="124" x2="${LEFT_X + PAGE_W}" y2="124" stroke="${INK_SOFT}" opacity="0.5"/>`;
    s += text(LEFT_X + 2, 144, "+ Añadir mi objetivo", { size: 12, fill: INK_RED });
    const rows = [["Ishi", "Montañas de Alterac · lobo negro", false], ["Garra", "Bosque de Elwynn · Cumplido el 12/10/2026", true]];
    if (st.wishAdded) rows.unshift(["Rey Bangalash", "Vega de Tuercespina · tigre raro", false]);
    rows.forEach(([n, d, done], i) => {
        const y = 170 + i * 36, fade = i === 0 && st.wishAdded ? prog(t, 28.3, 28.7) : 1;
        s += `<g opacity="${fade}">` + text(LEFT_X + 2, y, n, { size: 14, fill: done ? GREEN : HEAD, weight: "bold" }) +
            text(LEFT_X + 2, y + 14, d, { size: 10.5, fill: INK_SOFT }) + text(LEFT_X + PAGE_W - 6, y + 4, "×", { font: NUM, size: 15, fill: INK_SOFT, anchor: "end" }) + `</g>`;
    });
    return s;
}

function rightPetTabs(st) {
    let s = "";
    tabLabels.forEach(([id, label], i) => {
        const on = id === st.tab, x = tabX(i);
        s += text(x, 52, label, { font: TITLE, size: 19, fill: on ? INK : INK_SOFT, opacity: on ? 1 : 0.7, weight: on ? "bold" : null });
        if (on) s += `<line x1="${x}" y1="56" x2="${x + label.length * 10.4}" y2="56" stroke="${INK}" stroke-width="1.5"/>`;
    });
    s += `<line x1="${RIGHT_X}" y1="66" x2="${RIGHT_X + PAGE_W}" y2="66" stroke="${INK_SOFT}" opacity="0.5"/>`;
    return s;
}

function timeline(pet) {
    let s = `<g clip-path="url(#content)">`, y = 74, prev = null;
    const rows = pet.timeline || [];
    rows.forEach(([d, e, big, glyph], i) => {
        const showDate = d !== prev; prev = d;
        const lines = wrap(e, 40), h = Math.max(big ? 36 : 24, (showDate ? 15 : 2) + lines.length * 14 + 9);
        const nx = RIGHT_X + 16, ny = y + (showDate ? 15 : 9);
        s += `<line x1="${nx}" y1="${i === 0 ? ny : y}" x2="${nx}" y2="${i === rows.length - 1 ? ny : y + h}" stroke="${INK_SOFT}" opacity="0.35" stroke-width="2"/>`;
        if (big) {
            s += `<circle cx="${nx}" cy="${ny}" r="9" fill="#a8801e"/>` + text(nx, ny + 3.5, glyph, { font: SYM, size: 10, fill: "#fff", anchor: "middle" }) +
                `<image href="${IMG.ring64}" x="${nx - 15}" y="${ny - 15}" width="30" height="30"/>`;
        } else {
            s += `<circle cx="${nx}" cy="${ny}" r="6" fill="#7a6448"/>` + text(nx, ny + 2.8, glyph, { font: SYM, size: 7.5, fill: "#fff", anchor: "middle" });
        }
        if (showDate) s += text(RIGHT_X + 36, y + 11, d, { font: NUM, size: 9.5, fill: INK_RED });
        lines.forEach((l, k) => s += text(RIGHT_X + 36, y + (showDate ? 26 : 13) + k * 14, l, { size: 13, fill: big ? INK : INK_SOFT }));
        y += h;
    });
    return s + `</g>`;
}

function achievements() {
    let s = `<g clip-path="url(#content)">`;
    const got = ACH.filter((a) => a[1]).length;
    s += text(RIGHT_X + 2, 88, `${got} de 21 logros conseguidos`, { font: NUM, size: 12, fill: INK, weight: "bold" });
    s += text(RIGHT_X + 2, 102, "Siguiente: Manada de dos (412 / 1.000)", { font: NUM, size: 10, fill: INK_SOFT });
    ACH.forEach(([title, ok], i) => {
        const cx = RIGHT_X + 2 + (i % 6) * 52 + 26, cy = 74 + 40 + Math.floor(i / 6) * 44 + 22;
        s += medal(cx, cy, 38, ok ? "#a8801e" : "#8a8070", ok ? "★" : "", { dim: ok ? 1 : 0.55, ringOpacity: ok ? 1 : 0.8 });
    });
    return s + `</g>`;
}

function travels() {
    let s = `<g clip-path="url(#content)">`, y = 90;
    const section = (h, items) => {
        s += text(RIGHT_X, y, h, { size: 13, fill: HEAD, weight: "bold" }); y += 17;
        items.forEach(([n, d]) => { s += spans(RIGHT_X + 10, y, [[n + "  ", INK], [d, DIM]], { size: 12 }); y += 15; });
        y += 8;
    };
    section("Reinos del Este (5)", ZONES);
    section("Mazmorras (1)", [["Minas de la Muerte", "22/10/2026"]]);
    section("Jefes (3)", [["Edwin VanCleef", "x2"], ["Rhahk'Zor", "x2"], ["Sneed", "x1"]]);
    return s + `</g>`;
}

function codex(t) {
    // El contenido es más alto que el recuadro: se desplaza con la rueda para llegar a los retos.
    let s = `<g clip-path="url(#content)"><g transform="translate(0 ${-62 * prog(t, 32.9, 33.6)})">`;
    s += text(RIGHT_X + 2, 88, "5 de 17 familias domesticadas", { font: NUM, size: 12, fill: INK, weight: "bold" });
    FAMILIES.forEach(([name, state], i) => {
        const cx = RIGHT_X + 2 + (i % 6) * 52 + 26, cy = 74 + 26 + Math.floor(i / 6) * 44 + 22;
        s += medal(cx, cy, 38, FAMILY_COLORS[i], state === 0 ? "" : "✦", { dim: state === 1 ? 1 : state === 2 ? 0.7 : 0.3, ringOpacity: state === 1 ? 1 : 0.7, gray: state === 0 });
    });
    const gy = 74 + 26 + 3 * 44 + 6;
    s += text(RIGHT_X + 2, gy + 12, "Retos", { size: 13, fill: INK_RED, weight: "bold" });
    RETOS.forEach(([l, cur, goal], i) => {
        const done = cur >= goal;
        s += text(RIGHT_X, gy + 30 + i * 15, `· ${l}  (${Math.min(cur, goal)} / ${goal})`, { font: NUM, size: 11, fill: done ? GREEN : "#5a3a18" });
    });
    return s + `</g></g>`;
}

function settings(st) {
    let s = text(RIGHT_X, 52, "Ajustes", { font: TITLE, size: 19, fill: INK, weight: "bold" });
    s += `<line x1="${RIGHT_X}" y1="66" x2="${RIGHT_X + PAGE_W}" y2="66" stroke="${INK_SOFT}" opacity="0.5"/>`;
    OPTIONS.forEach((o, i) => {
        const on = !(i === 6 && st.optionOff), y = 74 + 4 + i * 26;
        s += `<image href="${on ? IMG.checkOn : IMG.checkOff}" x="${RIGHT_X - 2}" y="${y}" width="22" height="22"/>`;
        s += text(RIGHT_X + 26, y + 16, o, { size: 13, fill: INK });
    });
    return s;
}

function actionsRow(st) {
    let x = RIGHT_X, s = "";
    [["Compartir", INK_SOFT], ["Exportar", INK_SOFT], ["Despedirse", INK_SOFT], ["Borrar", INK_RED]].forEach(([l, c], i) => {
        if (i) { s += text(x + 4, 322, "·", { size: 11, fill: INK_SOFT }); x += 14; }
        s += text(x, 322, l, { size: 11, fill: c }); x += l.length * 5.6;
    });
    return s;
}

function book(t, st) {
    if (t < 5.0 || t > 39.4) return "";
    const open = prog(t, 5.3, 6.4), close = prog(t, 38.4, 39.2);
    const k = open * (1 - close), sc = BS * lerp(0.92, 1, open);
    const cx = 440, cy = 220;
    const pet = PETS[st.pet];
    let tabs = "";
    PETS.forEach((p, i) => { tabs += petTab(i, p, st.view === "pet" && i === st.pet, i === st.hoverPet); });
    tabs += wishMarker(st.view === "wishes");
    let left, right;
    if (st.view === "wishes") {
        left = leftPageWishes(t, st);
        right = text(RIGHT_X, 52, "Códice", { font: TITLE, size: 19, fill: INK, weight: "bold" }) +
            `<line x1="${RIGHT_X}" y1="66" x2="${RIGHT_X + PAGE_W}" y2="66" stroke="${INK_SOFT}" opacity="0.5"/>` + codex(t);
    } else {
        left = leftPagePet(pet);
        right = rightPetTabs(st) + (st.tab === "story" ? timeline(pet) : st.tab === "achievements" ? achievements() : travels());
        if (st.settings) right = "";
    }
    if (st.settings) right = settings(st);
    const g = `<g transform="translate(${BX + cx * BS} ${BY + cy * BS}) scale(${sc}) translate(${-cx} ${-cy})">
${tabs}
<image href="${IMG.book}" x="0" y="0" width="880" height="440" preserveAspectRatio="none"/>
${st.settings ? "" : ""}${left}${right}
${actionsRow(st)}
<g transform="translate(786 42)"><circle r="6" fill="none" stroke="#6b4a24" stroke-width="3" stroke-dasharray="2 2" opacity="0.75"/><circle r="2.5" fill="#6b4a24" opacity="0.75"/></g>
<image href="${IMG.cross}" x="800" y="34" width="16" height="16" opacity="0.8"/>
</g>`;
    return `<g opacity="${k}">${g}</g>`;
}

function tipBox(x, y, w, title, lines, o = {}) {
    const h = 22 + lines.length * 17 + 8;
    return `<g><rect x="${x}" y="${y}" width="${w}" height="${h}" rx="4" fill="#090c1a" opacity="0.94" stroke="#9a9a9a"/>
${text(x + 10, y + 19, title, { size: 15, fill: o.titleFill || "#ffd100", font: "Arial", weight: "bold" })}
${lines.map((l, i) => Array.isArray(l)
        ? text(x + 10, y + 39 + i * 17, l[0], { size: 12.5, fill: "#fff", font: "Arial" }) + text(x + w - 10, y + 39 + i * 17, l[1], { size: 12.5, fill: "#ffd100", font: "Arial", anchor: "end" })
        : text(x + 10, y + 39 + i * 17, l, { size: 12.5, fill: l.startsWith("+") ? "#7ac943" : "#fff", font: "Arial" })).join("")}
</g>`;
}

function tooltips(t, st) {
    const [mx, my] = mouseAt(t);
    if (st.hoverPet >= 0) {
        const p = PETS[st.hoverPet];
        return `<g opacity="${prog(t, 11.9, 12.0)}">` + tipBox(mx + 22, my + 14, 190, p.name, [`${p.family} · Nivel ${p.level}`, "+En el establo"], { titleFill: "#fff" }) + `</g>`;
    }
    if (st.statTip) return `<g opacity="${prog(t, 8.4, 8.7)}">` + tipBox(mx + 24, my - 120, 270, "Garra", ALL_STATS.map(([k, v]) => [k, v]), { titleFill: "#fff" }) + `</g>`;
    if (st.achTip) return `<g opacity="${prog(t, 17.6, 17.9)}">` + tipBox(mx + 24, my + 10, 250, "Manada de dos", ["Superad juntos 1.000 combates.", "+Progreso: 412 / 1.000"], { titleFill: "#fff" }) + `</g>`;
    if (st.codexTip) return `<g opacity="${prog(t, 31.0, 31.3)}">` + tipBox(mx - 310, my + 10, 280, "???", ["Una familia por descubrir. Se revela al", "domesticarla o al derrotar a una de sus bestias."], { titleFill: "#fff" }) + `</g>`;
    return "";
}

function chat(t) {
    if (t < 38.9 || t > 42.4) return "";
    const a = prog(t, 38.9, 39.3) * (1 - prog(t, 42.0, 42.4));
    return `<g opacity="${a}">
<rect x="30" y="500" width="540" height="120" fill="#000" opacity="0.35"/>
${spans(40, 540, [["[General]", "#ffc0c0"], [" Marta: ¿alguien para Minas de la Muerte?", "#ffc0c0"]], { size: 14, font: "Arial" })}
${spans(40, 562, [["Garra dice: ", "#ffff9f"], ["Nivel 35. Ya noto que corro más rápido.", "#ffff9f"]], { size: 14, font: "Arial" })}
${spans(40, 584, [["Garra consiguió un logro: ", "#ffff9f"], ["Manada de dos", "#ffd100"]], { size: 14, font: "Arial" })}
</g>`;
}

function cursor(t) {
    if (t < 3) return "";
    const [x, y] = mouseAt(t);
    const down = CLICKS.some((c) => t >= c && t < c + 0.15);
    const ripple = CLICKS.map((c) => { const k = (t - c) / 0.45; return k >= 0 && k <= 1 ?
        `<circle cx="${x}" cy="${y}" r="${6 + k * 18}" fill="none" stroke="#ffd36a" stroke-width="2" opacity="${1 - k}"/>` : ""; }).join("");
    const sc = down ? 0.88 : 1;
    return `${ripple}<g transform="translate(${x} ${y}) scale(${sc}) rotate(-8)">
<path d="M0 0 L0 24 L6 18 L11 29 L15 27 L10 16 L18 16 Z" fill="#e9d6a6" stroke="#3a2410" stroke-width="2" stroke-linejoin="round"/></g>`;
}

function caption(t) {
    const c = CAPTIONS.find(([a, b]) => t >= a && t < b);
    if (!c) return "";
    const a = prog(t, c[0], c[0] + 0.35) * (1 - prog(t, c[1] - 0.35, c[1]));
    return `<g opacity="${a}"><rect x="${W / 2 - 470}" y="${H - 52}" width="940" height="38" rx="19" fill="#0c0805" opacity="0.8" stroke="#8a6a32"/>
${text(W / 2, H - 27, c[2], { size: 17, fill: "#f3e3bd", anchor: "middle", font: "Georgia" })}</g>`;
}

function card(t, a, b, title, subtitle) {
    if (t < a || t > b) return "";
    const k = prog(t, a, a + 0.6) * (1 - prog(t, b - 0.5, b));
    const z = lerp(0.9, 1, prog(t, a, b));
    return `<g opacity="${k}"><rect width="${W}" height="${H}" fill="#0a0705"/>
<g transform="translate(${W / 2} 290) scale(${z})"><image href="${IMG.logo}" x="-150" y="-150" width="300" height="300"/></g>
${text(W / 2, 505, title, { font: TITLE, size: 54, fill: "#f0c862", anchor: "middle", weight: "bold" })}
${text(W / 2, 548, subtitle, { size: 20, fill: "#cdb88a", anchor: "middle", italic: true, font: "Georgia" })}</g>`;
}

function frame(t) {
    const st = state(t);
    return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}">
${background(t)}${minimap(t)}${book(t, st)}${tooltips(t, st)}${chat(t)}${cursor(t)}${caption(t)}
${card(t, 0, 3.2, "Vínculo", "El diario de tu mascota de cazador · WoW Classic, Era y Forever")}
${card(t, 42.2, DUR + 1, "Vínculo", "Próximamente en CurseForge")}
<text x="${W - 14}" y="${H - 8}" font-family="Arial" font-size="10" fill="#fff" opacity="0.35" text-anchor="end">Simulación de la interfaz · datos de ejemplo</text>
</svg>`;
}

const FONTS = ["pala.ttf", "palab.ttf", "palai.ttf", "georgia.ttf", "georgiab.ttf", "georgiai.ttf", "arial.ttf", "arialbd.ttf", "consola.ttf", "seguisym.ttf"]
    .map((f) => "C:/Windows/Fonts/" + f).filter((f) => fs.existsSync(f))
    .concat([path.join(MEDIA, "Fonts/IMFell.ttf"), path.join(MEDIA, "Fonts/Caveat.ttf")]);
const render = (t) => new Resvg(frame(t), { font: { loadSystemFonts: false, fontFiles: FONTS, defaultFontFamily: "Georgia" } }).render();

const args = process.argv.slice(2);
if (args[0] === "--frame") {
    for (const s of args.slice(1)) fs.writeFileSync(`frame-${s}.png`, render(+s).asPng());
    process.exit(0);
}
const out = args[0] || "vinculo-demo-v2.mp4";
const ff = spawn(FFMPEG, ["-y", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", `${W}x${H}`, "-r", String(FPS), "-i", "-",
    "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p", "-movflags", "+faststart", out], { stdio: ["pipe", "ignore", "inherit"] });
(async () => {
    const total = DUR * FPS;
    for (let i = 0; i < total; i++) {
        const px = render(i / FPS).pixels;
        if (!ff.stdin.write(px)) await new Promise((r) => ff.stdin.once("drain", r));
        if (i % 60 === 0) process.stdout.write(`\r${i}/${total}`);
    }
    ff.stdin.end();
    ff.on("close", (c) => console.log("\nffmpeg", c, out));
})();
