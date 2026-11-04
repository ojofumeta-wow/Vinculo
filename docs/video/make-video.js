// Vídeo de demostración de Vínculo (simulación con el arte real del addon).
// Uso: node make-video.js [out.mp4] [--frame segundos]
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");
const { spawn } = require("child_process");
const ROOT = "C:/Users/Javier/Desktop/WoW Addons/Vinculo";
const { Resvg } = require(path.join(ROOT, "_luatest/node_modules/@resvg/resvg-js"));
const FFMPEG = require("ffmpeg-static");

const W = 1280, H = 720, FPS = 30, DUR = 30;

// ---------- texturas ----------
function readTGA(file, cropW) {
    const b = fs.readFileSync(file);
    const w = b.readUInt16LE(12), h = b.readUInt16LE(14);
    const cw = cropW || w;
    const px = Buffer.alloc(cw * h * 4);
    for (let y = 0; y < h; y++) for (let x = 0; x < cw; x++) {
        const s = 18 + ((h - 1 - y) * w + x) * 4, d = (y * cw + x) * 4;
        px[d] = b[s + 2]; px[d + 1] = b[s + 1]; px[d + 2] = b[s]; px[d + 3] = b[s + 3];
    }
    return "data:image/png;base64," + png(cw, h, px).toString("base64");
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
    tab: readTGA(path.join(MEDIA, "Tab.tga"), 429),
    ring: readTGA(path.join(MEDIA, "Ring.tga")),
    logo: "data:image/png;base64," + fs.readFileSync(path.join(ROOT, "logo/logo.png")).toString("base64"),
};

// ---------- utilidades ----------
const clamp01 = (v) => Math.max(0, Math.min(1, v));
const ease = (v) => { v = clamp01(v); return v < 0.5 ? 2 * v * v : 1 - Math.pow(-2 * v + 2, 2) / 2; };
const prog = (t, a, b) => ease((t - a) / (b - a));
const lerp = (a, b, k) => a + (b - a) * k;
const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const TITLE = "Palatino Linotype", BODY = "Georgia";
const INK = "#3d240d", INK_SOFT = "#6b4a24", INK_RED = "#8a290d", HEAD = "#5a1e08", DIM = "#7a6448", GREEN = "#2f5a12";

function text(x, y, s, o = {}) {
    return `<text x="${x}" y="${y}" font-family="${o.font || BODY}" font-size="${o.size || 12}" fill="${o.fill || INK}"` +
        `${o.anchor ? ` text-anchor="${o.anchor}"` : ""}${o.weight ? ` font-weight="${o.weight}"` : ""}` +
        `${o.italic ? ` font-style="italic"` : ""}${o.opacity != null ? ` opacity="${o.opacity}"` : ""}` +
        `${o.stroke ? ` stroke="${o.stroke}" stroke-width="${o.sw || 3}" paint-order="stroke"` : ""}>${esc(s)}</text>`;
}
// Texto con tramos de color: [[texto, color], ...]
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

// ---------- datos de ejemplo ----------
const PETS = [
    {
        name: "Garra", family: "Lobo", level: 34, loyalty: "Fiel", happy: "Contenta", tint: "#c9b48a", active: true,
        since: "Juntos desde el 12/10/2026 · Os conocisteis en Bosque de Elwynn", tag: [["Contigo ahora", GREEN], ["  ·  ", DIM], ["Valiente", INK_RED]],
        note: "Le encanta perseguir conejos en Elwynn.",
        stats: [["Combates superados", "412"], ["Jefes", "9"], ["Zonas", "14"], ["Mazmorras", "3"], ["Tiempo juntos", "1d 6h"],
        ["En combate", "7h 12m"], ["Comidas", "58"], ["Caídas", "6"], ["Resurrecciones", "5"], ["Mejor racha", "131"],
        ["Tiempo contenta", "82 %"], ["Puntos de entrenamiento", "40 libres de 220"]],
        story: [["12/10", "Domesticaste a Garra en Bosque de Elwynn."], ["15/10", "Primera vez juntos en Páramos de Poniente."],
        ["19/10", "Garra alcanzó el nivel 20."], ["22/10", "Derrotasteis juntos a Edwin VanCleef."],
        ["22/10", "Logro: Cazadores de gigantes"], ["28/10", "Nueva lealtad: Fiel."], ["01/11", "Logro: Compañeros de caza"]],
    },
    {
        name: "Sombra", family: "Felino", level: 28, loyalty: "Leal", tint: "#9aa0b4",
        since: "Juntos desde el 20/10/2026 · Os conocisteis en Bosque del Ocaso", tag: [["En el establo", "#7a6a50"], ["  ·  ", DIM], ["Sigilosa", INK_RED]],
        note: "Silenciosa. Odia la lluvia.",
        stats: [["Combates superados", "187"], ["Jefes", "2"], ["Zonas", "6"], ["Mazmorras", "1"], ["Tiempo juntos", "14h 20m"],
        ["En combate", "3h 05m"], ["Comidas", "21"], ["Caídas", "3"], ["Resurrecciones", "3"], ["Mejor racha", "64"],
        ["Tiempo contenta", "-"], ["Puntos de entrenamiento", "-"]],
        story: [["20/10", "Domesticaste a Sombra en Bosque del Ocaso."], ["24/10", "Sombra alcanzó el nivel 25."],
        ["27/10", "Primera vez juntos en Montañas Crestagrana."], ["30/10", "Sombra estaba triste."], ["30/10", "Sombra vuelve a estar contenta."]],
    },
    { name: "Colmillo", family: "Jabalí", level: 12, tint: "#b08a6a" },
];
const ACH = [
    ["Primera presa", "Superad juntos vuestro primer combate.", "13/10"],
    ["Compañeros de caza", "Superad juntos 100 combates.", "01/11"],
    ["Manada de dos", "Superad juntos 1.000 combates.", null],
    ["Creciendo", "Tu mascota llega al nivel 20.", "19/10"],
    ["Cazadores de gigantes", "Derrotad juntos a un jefe.", "22/10"],
    ["Exploradores", "Visitad juntos 5 zonas.", "18/10"],
    ["Inseparables", "Pasad 10 horas juntos.", "24/10"],
];
const ZONES = [["Bosque de Elwynn", "12/10"], ["Páramos de Poniente", "15/10"], ["Bosque del Ocaso", "17/10"], ["Montañas Crestagrana", "20/10"], ["Los Humedales", "26/10"]];
const DUNGEONS = [["Minas de la Muerte", "22/10"]];
const BOSSES = [["Edwin VanCleef", "x2"], ["Rhahk'Zor", "x2"], ["Sneed", "x1"]];
const WISH = "Rey Bangalash, Vega de Tuercespina, tigre raro";

// ---------- guion (segundos) ----------
// Posición del libro en pantalla
const BS = 1.2, BX = 170, BY = 58;
const bx = (x) => BX + x * BS, by = (y) => BY + y * BS;
const LEFT_X = 75, RIGHT_X = 484, PAGE_W = 330;
const TAB_W = 150, TAB_H = 45, TAB_STEP = 48, TAB_OUT = 60;
const tabLabels = [["story", "Historia"], ["achievements", "Logros"], ["travels", "Viajes"], ["wishes", "Deseos"]];
function tabX(i) { let x = RIGHT_X; for (let k = 0; k < i; k++) x += tabLabels[k][1].length * 10.4 + 16; return x; }

// Puntos del ratón [t, x, y] en coordenadas de pantalla; clics en CLICKS.
const P = (x, y) => [bx(x), by(y)];
const MOUSE = [
    [6.0, 900, 690], [7.2, ...P(250, 160)], [8.6, ...P(250, 260)], [9.6, ...P(180, 370)],
    [10.6, ...P(-30, 24 + TAB_STEP + 22)], [12.4, ...P(-30, 24 + TAB_STEP + 22)],
    [13.6, ...P(-30, 24 + 22)], [14.0, ...P(-30, 24 + 22)],
    [15.0, ...P(tabX(1) + 25, 46)], [17.8, ...P(tabX(1) + 25, 46)],
    [18.6, ...P(tabX(2) + 25, 46)], [21.0, ...P(tabX(2) + 25, 46)],
    [21.8, ...P(tabX(3) + 25, 46)], [22.4, ...P(RIGHT_X + 120, 84)], [24.6, ...P(RIGHT_X + 120, 84)],
    [25.4, ...P(RIGHT_X + 76 + 5 + 35, 317)], [26.2, ...P(RIGHT_X + 76 + 5 + 35, 317)], [27, 1150, 690],
];
const CLICKS = [12.0, 13.9, 15.2, 18.8, 22.0, 22.6, 25.6];
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
        pet: t >= 12.0 && t < 13.9 ? 1 : 0,
        tab: t < 15.2 ? "story" : t < 18.8 ? "achievements" : t < 22.0 ? "travels" : "wishes",
        hoverPet: t >= 10.6 && t < 13.0 ? 1 : -1,
        wishTyped: t < 22.6 ? -1 : WISH.slice(0, Math.floor(clamp01((t - 22.8) / 1.6) * WISH.length)),
        wishAdded: t >= 24.6,
        export: t >= 25.6 && t < 28.5,
    };
}
const CAPTIONS = [
    [0, 3, ""],
    [3, 6, "Escribe /vinculo en el chat para abrir el diario"],
    [6, 10.4, "Cada mascota tiene su ficha: estadísticas, lealtad, ánimo y tu propia nota"],
    [10.4, 15, "Las pestañas de cuero son tus mascotas, también las del establo"],
    [15, 18.6, "Logros propios para cada compañera"],
    [18.6, 21.6, "Zonas, mazmorras y jefes que habéis visto juntos"],
    [21.6, 25.4, "Apunta las bestias que quieres domesticar: se marcan solas al conseguirlas"],
    [25.4, 28.5, "Exporta la historia de tu mascota para compartirla donde quieras"],
];

// ---------- dibujo ----------
function background(t) {
    const drift = t * 6;
    return `<defs>
<radialGradient id="bg" cx="50%" cy="45%" r="75%"><stop offset="0" stop-color="#2c3a2a"/><stop offset="0.6" stop-color="#16201a"/><stop offset="1" stop-color="#070a08"/></radialGradient>
<linearGradient id="btn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9b1c12"/><stop offset="1" stop-color="#4a0905"/></linearGradient>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.55"/></linearGradient>
</defs>
<rect width="${W}" height="${H}" fill="url(#bg)"/>
<g opacity="0.22" fill="#0c120d">
${[0, 1, 2, 3, 4, 5, 6, 7, 8].map((i) => { const x = (i * 170 + drift) % (W + 200) - 100, h = 260 + (i * 53) % 140;
        return `<path d="M${x} ${H} L${x + 60} ${H - h} L${x + 120} ${H} Z"/>`; }).join("")}
</g>
<rect width="${W}" height="${H}" fill="url(#sky)"/>`;
}

function chat(t) {
    if (t < 3 || t > 6.4) return "";
    const a = prog(t, 3, 3.4) * (1 - prog(t, 6.0, 6.4));
    const typed = "/vinculo".slice(0, Math.floor(clamp01((t - 3.8) / 1.0) * 8));
    const caret = Math.floor(t * 3) % 2 ? "|" : "";
    const lines = [["[General]", "#ffc0c0", " Marta: ¿alguien para Minas de la Muerte?"], ["", "#ffd100", "Vínculo cargado. Escribe /vinculo para abrir el diario."]];
    return `<g opacity="${a}">
<rect x="30" y="500" width="460" height="120" fill="#000" opacity="0.35"/>
${lines.map((l, i) => spans(40, 540 + i * 20, [[l[0], l[1]], [l[2], l[0] ? "#ffc0c0" : "#ffd100"]], { size: 14, font: "Arial" })).join("")}
<rect x="30" y="630" width="460" height="28" fill="#000" opacity="0.7" stroke="#6b6b6b"/>
${text(40, 650, "Decir: " + typed + caret, { size: 15, fill: "#fff", font: "Arial" })}
</g>`;
}

function petTab(i, pet, selected, hover) {
    const x = -(selected ? TAB_OUT + 10 : TAB_OUT), y = 24 + i * TAB_STEP;
    const ix = x + TAB_W * 0.1675, iy = y + TAB_H / 2 + 1, r = TAB_H * 0.21;
    return `<g>
<image href="${IMG.tab}" x="${x}" y="${y}" width="${TAB_W}" height="${TAB_H}" preserveAspectRatio="none"/>
<circle cx="${ix}" cy="${iy}" r="${r + 1}" fill="#20140a"/>
${PAW(ix, iy + 1, r * 0.8, pet.tint)}
${selected ? `<circle cx="${ix}" cy="${iy}" r="${r + 3}" fill="none" stroke="#ffd36a" stroke-width="2" opacity="0.9"/>` : ""}
${hover ? `<circle cx="${ix}" cy="${iy}" r="${r + 1}" fill="#fff" opacity="0.18"/>` : ""}
</g>`;
}

function leftPage(pet) {
    let s = "";
    // Retrato
    s += `<rect x="${LEFT_X - 6}" y="34" width="84" height="84" fill="#1a110a" rx="42"/>`;
    s += PAW(LEFT_X + 36, 78, 22, pet.tint);
    s += `<image href="${IMG.ring}" x="${LEFT_X - 14}" y="26" width="100" height="100"/>`;
    s += text(LEFT_X + 92, 66, pet.name, { font: TITLE, size: 26, fill: INK, weight: "bold" });
    const sub = [[`${pet.family} · Nivel ${pet.level} · ${pet.loyalty}`, INK_SOFT]];
    if (pet.happy) sub.push([" · ", INK_SOFT], [pet.happy, GREEN]);
    s += spans(LEFT_X + 92, 84, sub, { size: 11 });
    wrap(pet.since, 38).forEach((l, i) => s += text(LEFT_X + 92, 98 + i * 12, l, { size: 9.5, fill: DIM }));
    s += spans(LEFT_X + 92, 124, pet.tag, { size: 10.5 });
    s += `<line x1="${LEFT_X}" y1="128" x2="${LEFT_X + PAGE_W}" y2="128" stroke="${INK_SOFT}" opacity="0.5"/>`;
    pet.stats.forEach(([k, v], i) => {
        const y = 132 + i * 18 + 11;
        s += text(LEFT_X + 4, y, k, { size: 11.5, fill: INK_SOFT });
        s += text(LEFT_X + PAGE_W - 4, y, v, { size: 11.5, fill: INK, anchor: "end", weight: "bold" });
        s += `<line x1="${LEFT_X}" y1="${y + 4}" x2="${LEFT_X + PAGE_W}" y2="${y + 4}" stroke="${INK_SOFT}" opacity="0.18"/>`;
    });
    s += text(LEFT_X + 2, 366, pet.note, { size: 11.5, fill: INK, italic: true });
    s += `<line x1="${LEFT_X}" y1="372" x2="${LEFT_X + PAGE_W}" y2="372" stroke="${INK_SOFT}" opacity="0.6"/>`;
    return s;
}

function rightPage(t, st, pet) {
    let s = "";
    tabLabels.forEach(([id, label], i) => {
        const on = id === st.tab, x = tabX(i);
        s += text(x, 52, label, { font: TITLE, size: 19, fill: on ? INK : INK_SOFT, opacity: on ? 1 : 0.7, weight: on ? "bold" : null });
        if (on) s += `<line x1="${x}" y1="56" x2="${x + label.length * 10.4}" y2="56" stroke="${INK}" stroke-width="1.5"/>`;
    });
    const top = 74;
    if (st.tab === "story") {
        s += text(RIGHT_X, 68, "Su historia", { size: 10, fill: DIM, italic: true });
        let y = top + 12;
        pet.story.forEach(([d, e]) => {
            s += text(RIGHT_X, y, d, { size: 11, fill: INK_RED, weight: "bold" });
            wrap(e, 44).forEach((l, i) => { s += text(RIGHT_X + 42, y + i * 14, l, { size: 11.5 }); });
            y += wrap(e, 44).length * 14 + 9;
        });
    } else if (st.tab === "achievements") {
        const got = ACH.filter((a) => a[2]).length;
        s += text(RIGHT_X, 68, `${got} de 21 logros`, { size: 10, fill: DIM, italic: true });
        ACH.slice(0, 6).forEach(([title, desc, when], i) => {
            const y = top + 4 + i * 36;
            s += `<rect x="${RIGHT_X}" y="${y}" width="28" height="28" rx="3" fill="${when ? "#3a2412" : "#5b5246"}" stroke="${when ? "#c9a24a" : "#8a8070"}" stroke-width="1.5"/>`;
            s += PAW(RIGHT_X + 14, y + 15, 9, when ? "#e8c46a" : "#9a9184");
            s += text(RIGHT_X + 36, y + 11, title, { size: 12, fill: when ? HEAD : DIM, weight: "bold" });
            s += text(RIGHT_X + 36, y + 25, desc, { size: 10, fill: INK_SOFT, opacity: when ? 1 : 0.7 });
            if (when) s += text(RIGHT_X + PAGE_W - 22, y + 18, when, { size: 10, fill: INK_RED, anchor: "end" });
        });
    } else if (st.tab === "travels") {
        s += text(RIGHT_X, 68, "5 zonas · 1 mazmorra · 3 jefes", { size: 10, fill: DIM, italic: true });
        let y = top + 14;
        const section = (h, items) => {
            s += text(RIGHT_X, y, h, { size: 12, fill: HEAD, weight: "bold" }); y += 16;
            items.forEach(([n, d]) => { s += spans(RIGHT_X + 10, y, [[n + "  ", INK], [d, DIM]], { size: 11.5 }); y += 15; });
            y += 8;
        };
        section(`Zonas (${ZONES.length})`, ZONES);
        section(`Mazmorras (${DUNGEONS.length})`, DUNGEONS);
        section(`Jefes (${BOSSES.length})`, BOSSES);
    } else {
        s += text(RIGHT_X, 68, "Bestias que quieres domesticar", { size: 10, fill: DIM, italic: true });
        const y = top + 2;
        const typing = st.wishTyped !== -1 && !st.wishAdded;
        const v = typing ? st.wishTyped + (Math.floor(t * 3) % 2 ? "|" : "") : "";
        s += text(RIGHT_X + 2, y + 15, v || "Bestia, zona, nota (Intro para añadir)", { size: 11.5, fill: v ? INK : DIM, italic: !v });
        s += `<line x1="${RIGHT_X}" y1="${y + 21}" x2="${RIGHT_X + PAGE_W - 22}" y2="${y + 21}" stroke="${INK_SOFT}" opacity="0.6"/>`;
        let yy = y + 42;
        const rows = [["Ishi", "Montañas de Alterac · lobo negro"]];
        if (st.wishAdded) rows.unshift(["Rey Bangalash", "Vega de Tuercespina · tigre raro"]);
        rows.forEach(([n, d], i) => {
            const fade = i === 0 && st.wishAdded ? prog(t, 24.6, 25.0) : 1;
            s += `<g opacity="${fade}">` + text(RIGHT_X + 2, yy, n, { size: 12, fill: HEAD, weight: "bold" }) +
                text(RIGHT_X + 2, yy + 14, d, { size: 10.5, fill: INK_SOFT }) +
                text(RIGHT_X + PAGE_W - 30, yy + 6, "✕", { size: 12, fill: INK_RED, anchor: "end" }) + `</g>`;
            yy += 34;
        });
        s += text(RIGHT_X + 2, yy + 4, "Cumplido: Garra (12/10)", { size: 10, fill: GREEN, italic: true });
    }
    // Botones
    let x = RIGHT_X;
    [["Compartir", 76], ["Exportar", 70], ["Despedirse", 82], ["Borrar", 60]].forEach(([l, w]) => {
        s += `<rect x="${x}" y="306" width="${w}" height="22" rx="3" fill="url(#btn)" stroke="#c9a24a" stroke-width="1"/>`;
        s += text(x + w / 2, 321, l, { size: 11, fill: "#ffd100", anchor: "middle", font: "Arial" });
        x += w + 5;
    });
    return s;
}

function book(t, st) {
    if (t < 5.3) return "";
    const k = prog(t, 5.3, 6.1), sc = BS * lerp(0.92, 1, k);
    const cx = 440, cy = 220;
    const pet = PETS[st.pet];
    let tabs = "";
    PETS.forEach((p, i) => { tabs += petTab(i, p, i === st.pet, i === st.hoverPet); });
    const g = `<g transform="translate(${BX + cx * BS} ${BY + cy * BS}) scale(${sc}) translate(${-cx} ${-cy})">
${tabs}
<image href="${IMG.book}" x="0" y="0" width="880" height="440" preserveAspectRatio="none"/>
${text(LEFT_X + PAGE_W / 2, 18, "Vínculo", { font: TITLE, size: 17, fill: "#f0c862", anchor: "middle", weight: "bold", stroke: "#2a1606", sw: 3 })}
${text(866, 20, "✕", { size: 14, fill: "#e8c46a", anchor: "middle" })}
${leftPage(pet)}
${rightPage(t, st, pet)}
</g>`;
    return `<g opacity="${k}">${g}</g>`;
}

function tooltip(t, st) {
    if (st.hoverPet < 0) return "";
    const p = PETS[st.hoverPet];
    const [mx, my] = mouseAt(t), x = mx + 22, y = my + 14;
    return `<g opacity="${prog(t, 10.9, 11.1)}">
<rect x="${x}" y="${y}" width="200" height="66" rx="4" fill="#090c1a" opacity="0.92" stroke="#9a9a9a"/>
${text(x + 10, y + 21, p.name, { size: 15, fill: "#fff", font: "Arial" })}
${text(x + 10, y + 40, `${p.family} · Nivel ${p.level}`, { size: 13, fill: "#fff", font: "Arial" })}
${text(x + 10, y + 57, "En el establo", { size: 13, fill: "#999", font: "Arial" })}
</g>`;
}

function exportPanel(t, st) {
    if (!st.export) return "";
    const a = prog(t, 25.6, 25.9) * (1 - prog(t, 28.2, 28.5));
    const x = 340, y = 150, w = 600, h = 400;
    const lines = ["Vínculo · Diario de Garra", "Lobo, nivel 34 · Fiel · Juntos desde el 12/10/2026", "",
        "[Vínculo] Garra (Lobo, nivel 34) · Combates: 412 · Jefes: 9", "Juntos: 1d 6h · Logros: 9/21", "",
        "Nota: Le encanta perseguir conejos en Elwynn.", "",
        ...PETS[0].story.map(([d, e]) => d + "  " + e)];
    return `<g opacity="${a}">
<rect width="${W}" height="${H}" fill="#000" opacity="0.35"/>
<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="6" fill="#0b0b0b" opacity="0.95" stroke="#8a7a5a" stroke-width="2"/>
${text(x + 16, y + 28, "Diario de Garra", { size: 17, fill: "#ffd100", font: TITLE, weight: "bold" })}
${text(x + w - 18, y + 26, "✕", { size: 15, fill: "#ddd", anchor: "end" })}
<rect x="${x + 14}" y="${y + 44}" width="${w - 28}" height="${lines.length * 19 + 8}" fill="#2a4a8a" opacity="0.55"/>
${lines.map((l, i) => text(x + 20, y + 62 + i * 19, l, { size: 13, fill: "#fff", font: "Consolas" })).join("")}
${text(x + 16, y + h - 14, "Ctrl+C para copiar · Esc para cerrar", { size: 12, fill: "#aaa", font: "Arial" })}
</g>`;
}

function cursor(t) {
    if (t < 6) return "";
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
    if (!c || !c[2]) return "";
    const a = prog(t, c[0], c[0] + 0.35) * (1 - prog(t, c[1] - 0.35, c[1]));
    return `<g opacity="${a}"><rect x="${W / 2 - 430}" y="${H - 52}" width="860" height="38" rx="19" fill="#0c0805" opacity="0.8" stroke="#8a6a32"/>
${text(W / 2, H - 27, c[2], { size: 18, fill: "#f3e3bd", anchor: "middle", font: BODY })}</g>`;
}

function card(t, a, b, title, subtitle) {
    if (t < a || t > b) return "";
    const k = prog(t, a, a + 0.6) * (1 - prog(t, b - 0.5, b));
    const z = lerp(0.9, 1, prog(t, a, b));
    return `<g opacity="${k}"><rect width="${W}" height="${H}" fill="#0a0705"/>
<g transform="translate(${W / 2} 290) scale(${z})"><image href="${IMG.logo}" x="-150" y="-150" width="300" height="300"/></g>
${text(W / 2, 505, title, { font: TITLE, size: 54, fill: "#f0c862", anchor: "middle", weight: "bold" })}
${text(W / 2, 548, subtitle, { size: 20, fill: "#cdb88a", anchor: "middle", italic: true })}</g>`;
}

function frame(t) {
    const st = state(t);
    return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}">
${background(t)}${chat(t)}${book(t, st)}${tooltip(t, st)}${exportPanel(t, st)}${cursor(t)}${caption(t)}
${card(t, 0, 3.2, "Vínculo", "El diario de tu mascota de cazador · WoW Forever")}
${card(t, 28.2, DUR + 1, "Vínculo", "Próximamente en CurseForge")}
<text x="${W - 14}" y="${H - 8}" font-family="Arial" font-size="10" fill="#fff" opacity="0.35" text-anchor="end">Simulación de la interfaz · datos de ejemplo</text>
</svg>`;
}

const FONTS = ["pala.ttf", "palab.ttf", "palai.ttf", "georgia.ttf", "georgiab.ttf", "georgiai.ttf", "arial.ttf", "consola.ttf", "seguisym.ttf"]
    .map((f) => "C:/Windows/Fonts/" + f).filter((f) => fs.existsSync(f));
const render = (t) => new Resvg(frame(t), { font: { loadSystemFonts: false, fontFiles: FONTS, defaultFontFamily: "Georgia" } }).render();

const args = process.argv.slice(2);
if (args[0] === "--frame") {
    for (const s of args.slice(1)) {
        const img = render(+s);
        fs.writeFileSync(`frame-${s}.png`, img.asPng());
    }
    process.exit(0);
}
const out = args[0] || "vinculo-demo.mp4";
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
