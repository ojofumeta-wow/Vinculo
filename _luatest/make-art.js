// Pasa las imágenes de art/ a texturas .tga para WoW (Vinculo/Media/).
// Uso: node _luatest/make-art.js
const fs = require("fs");
const path = require("path");
const { Resvg } = require("@resvg/resvg-js");

const ROOT = path.join(__dirname, "..");
const ART = path.join(ROOT, "art");
const OUT = path.join(ROOT, "Vinculo", "Media");
fs.mkdirSync(OUT, { recursive: true });

// Recorta [x, y, w, h] del original y lo escala a dw×dh, colocado en (dx, dy) de un lienzo W×H.
function render(file, crop, W, H, place) {
    const b64 = fs.readFileSync(path.join(ART, file)).toString("base64");
    const [x, y, w, h] = crop;
    const [dx, dy, dw, dh] = place || [0, 0, W, H];
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${W}" height="${H}">
<svg x="${dx}" y="${dy}" width="${dw}" height="${dh}" viewBox="${x} ${y} ${w} ${h}" preserveAspectRatio="none">
<image href="data:image/jpeg;base64,${b64}" x="0" y="0" width="${crop[4]}" height="${crop[5]}"/></svg></svg>`;
    const img = new Resvg(svg).render();
    return { w: img.width, h: img.height, px: Buffer.from(img.pixels) };
}

// Quita el magenta: alfa según cuánto magenta hay y se resta su mezcla del color.
function keyMagenta(img) {
    const p = img.px;
    for (let i = 0; i < p.length; i += 4) {
        if (p[i + 3] === 0) continue;
        const r = p[i], g = p[i + 1], b = p[i + 2];
        const m = Math.min(r, b) - g;
        let a = 1 - Math.min(Math.max((m - 40) / 140, 0), 1);
        if (a <= 0.02) { p[i] = 48; p[i + 1] = 32; p[i + 2] = 16; p[i + 3] = 0; continue; }
        if (a < 1) {
            p[i] = clamp((r - (1 - a) * 255) / a);
            p[i + 1] = clamp(g / a);
            p[i + 2] = clamp((b - (1 - a) * 255) / a);
            // Sin esto queda un tinte rosa en el borde.
            const lim = Math.max(p[i + 1], Math.min(p[i], p[i + 2]) * 0.8);
            p[i] = Math.min(p[i], lim + 40); p[i + 2] = Math.min(p[i + 2], lim);
        }
        p[i + 3] = Math.round(a * 255);
    }
}

// Quita el fondo blanco solo desde los bordes, para no comerse el pergamino.
function keyWhiteFromEdges(img) {
    const { w, h, px } = img;
    const white = (k) => px[k] > 215 && px[k + 1] > 215 && px[k + 2] > 210;
    const seen = new Uint8Array(w * h);
    const stack = [];
    for (let x = 0; x < w; x++) stack.push(x, (h - 1) * w + x);
    for (let y = 0; y < h; y++) stack.push(y * w, y * w + w - 1);
    while (stack.length) {
        const i = stack.pop();
        if (seen[i] || !white(i * 4)) continue;
        seen[i] = 1;
        px[i * 4 + 3] = 0;
        const x = i % w, y = (i / w) | 0;
        if (x > 0) stack.push(i - 1);
        if (x < w - 1) stack.push(i + 1);
        if (y > 0) stack.push(i - w);
        if (y < h - 1) stack.push(i + w);
    }
    // Suaviza el borde: los vecinos del fondo quedan semitransparentes.
    for (let i = 0; i < w * h; i++) {
        if (seen[i]) continue;
        const x = i % w, y = (i / w) | 0;
        if ((x > 0 && seen[i - 1]) || (x < w - 1 && seen[i + 1]) || (y > 0 && seen[i - w]) || (y < h - 1 && seen[i + w])) {
            px[i * 4 + 3] = 140;
        }
    }
}

function clamp(v) { return Math.max(0, Math.min(255, Math.round(v))); }

// TGA de 32 bits sin comprimir, filas de abajo arriba (lo que WoW lee siempre).
function writeTGA(img, name) {
    const { w, h, px } = img;
    const out = Buffer.alloc(18 + w * h * 4);
    out[2] = 2;
    out.writeUInt16LE(w, 12);
    out.writeUInt16LE(h, 14);
    out[16] = 32;
    out[17] = 8;
    let o = 18;
    for (let y = h - 1; y >= 0; y--) {
        for (let x = 0; x < w; x++) {
            const i = (y * w + x) * 4;
            out[o++] = px[i + 2]; out[o++] = px[i + 1]; out[o++] = px[i]; out[o++] = px[i + 3];
        }
    }
    fs.writeFileSync(path.join(OUT, name), out);
    console.log(name, w + "x" + h);
}

// Archivos: [nombre, ancho original, alto original]
const BOOK = ["Gemini_Generated_Image_nzoefonzoefonzoe.jpg", 2912, 1440];
const TAB = ["Gemini_Generated_Image_1ucmk21ucmk21ucm.jpg", 2752, 1536];
const RING = ["Gemini_Generated_Image_v1dbxev1dbxev1db.jpg", 2048, 2048];

const book = render(BOOK[0], [0, 0, BOOK[1], BOOK[2], BOOK[1], BOOK[2]], 1024, 512);
keyWhiteFromEdges(book);
writeTGA(book, "Book.tga");

// La pestaña ocupa 2280×680 del original; se escala sin deformar (429×128) y el resto queda vacío.
const tab = render(TAB[0], [230, 430, 2280, 680, TAB[1], TAB[2]], 512, 128, [0, 0, 429, 128]);
keyMagenta(tab);
writeTGA(tab, "Tab.tga");

const ring = render(RING[0], [0, 0, RING[1], RING[2], RING[1], RING[2]], 256, 256);
keyMagenta(ring);
writeTGA(ring, "Ring.tga");

function writePNG(img, file) {
    const zlib = require("zlib");
    const raw = Buffer.alloc((img.w * 4 + 1) * img.h);
    for (let y = 0; y < img.h; y++) img.px.copy(raw, y * (img.w * 4 + 1) + 1, y * img.w * 4, (y + 1) * img.w * 4);
    const chunk = (t, d) => {
        const len = Buffer.alloc(4); len.writeUInt32BE(d.length);
        const td = Buffer.concat([Buffer.from(t), d]);
        const crc = Buffer.alloc(4); crc.writeUInt32BE(zlib.crc32 ? zlib.crc32(td) >>> 0 : crc32(td));
        return Buffer.concat([len, td, crc]);
    };
    const ihdr = Buffer.alloc(13);
    ihdr.writeUInt32BE(img.w, 0); ihdr.writeUInt32BE(img.h, 4); ihdr[8] = 8; ihdr[9] = 6;
    fs.writeFileSync(file, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
        chunk("IHDR", ihdr), chunk("IDAT", zlib.deflateSync(raw)), chunk("IEND", Buffer.alloc(0))]));
}

// Logo de CurseForge: el medallión centrado, 512×512, en PNG con transparencia.
const LOGO = ["Gemini_Generated_Image_huukcrhuukcrhuuk.jpg", 2048, 2048];
const logo = render(LOGO[0], [85, 88, 1860, 1860, LOGO[1], LOGO[2]], 512, 512);
keyMagenta(logo);
writePNG(logo, path.join(ROOT, "logo", "logo.png"));
console.log("logo.png 512x512");

// Vista previa en PNG para revisar sin abrir el juego.
if (process.argv.includes("--preview")) {
    for (const [img, name] of [[book, "Book"], [tab, "Tab"], [ring, "Ring"]]) {
        writePNG(img, path.join(process.argv[process.argv.indexOf("--preview") + 1], name + ".png"));
    }
}

function crc32(buf) {
    let c, crc = 0xffffffff;
    for (let n = 0; n < buf.length; n++) {
        c = (crc ^ buf[n]) & 0xff;
        for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
        crc = (crc >>> 8) ^ c;
    }
    return (crc ^ 0xffffffff) >>> 0;
}
