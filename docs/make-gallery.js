// Monta las capturas de dist/capturas como "páginas de diario de campo": pergamino, foto con cinta
// y notas a mano con flechas. Salida: dist/galeria (1280x720). Uso: node docs/make-gallery.js
const fs = require("fs");
const path = require("path");
const { Resvg } = require("../_luatest/node_modules/@resvg/resvg-js");

const root = path.resolve(__dirname, "..");
const out = path.join(root, "dist", "galeria");
fs.mkdirSync(out, { recursive: true });
const fonts = ["IMFell.ttf", "Caveat.ttf"].map(f => path.join(root, "Vinculo", "Media", "Fonts", f));
const logo = fs.readFileSync(path.join(root, "logo", "logo.png")).toString("base64");

const INK = "#3a1f0c", RED = "#8a2410";
// side: lado de la foto. notes: líneas de texto + punto de la captura (fx, fy en 0..1) al que apunta la flecha.
const slides = [
  { file: "01-ficha-historia", out: "01-ficha-historia", n: "I", side: "R", rot: -1.2, title: "Vínculo", sub: ["Your hunter pet's story,", "in a leather-bound journal."],
    notes: [{ t: ["Where and when", "you first met"], fx: .34, fy: .25 }, { t: ["A page for every pet:", "stats with a story each"], fx: .31, fy: .40 }] },
  { file: "02-bestiario-autocompletar", out: "02-bestiario-autocompletar", n: "II", side: "R", rot: 1.1, title: "Bestiary", sub: ["Plan your next tame."],
    notes: [{ t: ["Type \"wolf\" and pick one:", "the zone fills in itself"], fx: .30, fy: .52 }, { t: ["The Codex fills in", "as you meet each family"], fx: .70, fy: .52 }] },
  { file: "06-ver-mapa", out: "03-ver-mapa", n: "III", side: "L", rot: -1.1, title: "Show on map", sub: ["From your wish list", "to the world map."],
    notes: [{ t: ["One click opens the map", "right at the zone"], fx: .77, fy: .385 }, { t: ["...and marks it with", "the Vínculo icon"], fx: .52, fy: .73 }] },
  { file: "03-logros-tooltip", out: "04-logros", n: "IV", side: "L", rot: 1, title: "Achievements", sub: ["21 medals of their own."],
    notes: [{ t: ["Your first medal,", "earned on day one"], fx: .553, fy: .325, bow: -150 }, { t: ["Hover any medal", "to see its progress"], fx: .89, fy: .395 }] },
  { file: "07-tooltip-bestia", out: "05-tooltip-bestia", n: "V", side: "R", rot: 1.2, ring: false, title: "Beast tooltips", sub: ["Know before you tame."],
    notes: [{ t: ["Is it on your wish list?"], fx: .55, fy: .85 }, { t: ["Which pet skill", "it teaches"], fx: .55, fy: .90 }, { t: ["Do you already own", "its family?"], fx: .55, fy: .945 }] },
  { file: "05-aviso-logro", out: "06-aviso-logro", n: "VI", side: "R", rot: -1, title: "Achievement alerts", sub: ["Styled like the game's own banner."],
    notes: [{ t: ["Turn it off any time", "in the settings"], fx: .868, fy: .12 }, { t: ["Same banner as the game,", "with the Vínculo logo"], fx: .55, fy: .91 }] },
  { file: "04-viajes", out: "07-viajes", n: "VII", side: "L", rot: 1.1, title: "Journeys", sub: ["Every zone you have", "walked together."],
    notes: [{ t: ["Grouped by continent,", "with the day of your visit"], fx: .64, fy: .21 }, { t: ["A tab of its own", "in the journal"], fx: .82, fy: .14 }] },
];

const W = 1280, H = 720;
const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;");
const rot = (x, y, cx, cy, deg) => {
  const a = deg * Math.PI / 180, dx = x - cx, dy = y - cy;
  return [cx + dx * Math.cos(a) - dy * Math.sin(a), cy + dx * Math.sin(a) + dy * Math.cos(a)];
};

const defs = `<defs>
 <radialGradient id="par" cx="50%" cy="45%" r="75%"><stop offset="0" stop-color="#f3e4bb"/><stop offset="0.7" stop-color="#e2c994"/><stop offset="1" stop-color="#b88f55"/></radialGradient>
 <radialGradient id="burn" cx="50%" cy="50%" r="72%"><stop offset="0.62" stop-color="#2a1205" stop-opacity="0"/><stop offset="1" stop-color="#2a1205" stop-opacity="0.55"/></radialGradient>
 <linearGradient id="leather" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a2a14"/><stop offset="1" stop-color="#26130a"/></linearGradient>
 <filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="3" seed="4"/>
  <feColorMatrix type="matrix" values="0 0 0 0 0.30  0 0 0 0 0.18  0 0 0 0 0.06  0 0 0 1.1 -0.45"/></filter>
 <filter id="stain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.011" numOctaves="3" seed="9"/>
  <feColorMatrix type="matrix" values="0 0 0 0 0.45  0 0 0 0 0.27  0 0 0 0 0.08  0 0 0 1.4 -0.55"/></filter>
 <filter id="sh" x="-15%" y="-15%" width="130%" height="140%"><feDropShadow dx="2" dy="9" stdDeviation="9" flood-color="#2a1205" flood-opacity="0.55"/></filter>
 <filter id="ssh" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="1" dy="4" stdDeviation="3" flood-color="#2a1205" flood-opacity="0.5"/></filter>
 <marker id="ah" markerWidth="12" markerHeight="12" refX="9" refY="6" orient="auto" markerUnits="userSpaceOnUse"><path d="M1,1 L10,6 L1,11" fill="none" stroke="${RED}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></marker>
</defs>`;

const bg = `<rect width="${W}" height="${H}" fill="url(#leather)"/>
<rect width="${W}" height="${H}" filter="url(#grain)" opacity="0.5"/>
<rect x="26" y="26" width="${W - 52}" height="${H - 52}" rx="12" fill="url(#par)" filter="url(#sh)"/>
<rect x="26" y="26" width="${W - 52}" height="${H - 52}" rx="12" filter="url(#stain)" opacity="0.5"/>
<rect x="26" y="26" width="${W - 52}" height="${H - 52}" rx="12" filter="url(#grain)" opacity="0.35"/>
<rect x="26" y="26" width="${W - 52}" height="${H - 52}" rx="12" fill="url(#burn)"/>
<rect x="40" y="40" width="${W - 80}" height="${H - 80}" rx="8" fill="none" stroke="#7a5a30" stroke-width="1.6" stroke-dasharray="9 6" opacity="0.55"/>`;

for (const s of slides) {
  const src = path.join(root, "dist", "capturas", s.file + ".png");
  if (!fs.existsSync(src)) { console.log("falta", s.file); continue; }
  const png = fs.readFileSync(src);
  const iw = png.readUInt32BE(16), ih = png.readUInt32BE(20);
  const PW = Math.round(Math.min(830, 420 * iw / ih)), PH = Math.round(PW * ih / iw);
  const px = s.side === "L" ? 70 : W - 70 - PW;
  const py = Math.round(372 - PH / 2);
  const cx = px + PW / 2, cy = py + PH / 2;
  const colX = s.side === "L" ? px + PW + 50 : 78;
  const colEnd = s.side === "L" ? W - 70 : px - 40;

  let g = defs + bg;
  // columna de texto
  g += `<text x="${colX}" y="92" font-family="IM FELL English" font-size="18" letter-spacing="2" fill="${RED}">FIELD NOTES · ${s.n}</text>`;
  const tsize = Math.min(70, Math.floor((colEnd - colX) / (s.title.length * 0.43)));
  g += `<text x="${colX}" y="${92 + tsize}" font-family="Caveat" font-weight="700" font-size="${tsize}" fill="${INK}">${esc(s.title)}</text>`;
  const uw = Math.min(colEnd - colX, s.title.length * tsize * 0.46);
  const uy = 92 + tsize + 12;
  g += `<path d="M${colX},${uy} q${uw / 6},-7 ${uw / 3},0 t${uw / 3},0 t${uw / 3},0" fill="none" stroke="${RED}" stroke-width="3" stroke-linecap="round"/>`;
  s.sub.forEach((l, i) => { g += `<text x="${colX}" y="${uy + 38 + i * 30}" font-family="IM FELL English" font-style="italic" font-size="25" fill="${INK}">${esc(l)}</text>`; });

  // foto con marco de papel y cinta
  g += `<g transform="rotate(${s.rot} ${cx} ${cy})">
   <rect x="${px - 12}" y="${py - 12}" width="${PW + 24}" height="${PH + 24}" fill="#f6ecd2" filter="url(#sh)"/>
   <image x="${px}" y="${py}" width="${PW}" height="${PH}" xlink:href="data:image/png;base64,${png.toString("base64")}"/>
   <rect x="${px}" y="${py}" width="${PW}" height="${PH}" fill="none" stroke="#2a1205" stroke-opacity="0.5" stroke-width="1.5"/>
   <rect x="${px - 34}" y="${py - 22}" width="92" height="30" fill="#e9d7a0" fill-opacity="0.82" transform="rotate(-36 ${px + 12} ${py - 7})" filter="url(#ssh)"/>
   <rect x="${px + PW - 58}" y="${py - 22}" width="92" height="30" fill="#e9d7a0" fill-opacity="0.82" transform="rotate(34 ${px + PW - 12} ${py - 7})" filter="url(#ssh)"/>
  </g>`;

  // notas a mano con flecha
  const n = s.notes.length, gap = n === 3 ? 92 : 118, y0 = n === 3 ? 340 : 372;
  s.notes.forEach((nt, i) => {
    const ny = y0 + i * gap;
    let w = 0;
    nt.t.forEach((l, j) => { w = Math.max(w, l.length * 13.2); g += `<text x="${colX}" y="${ny + j * 32}" font-family="Caveat" font-size="31" fill="${RED}">${esc(nt.t[j])}</text>`; });
    const [tx, ty] = rot(px + nt.fx * PW, py + nt.fy * PH, cx, cy, s.rot);
    const sx = s.side === "L" ? colX - 12 : colX + w + 12, sy = ny - 8 + (nt.t.length - 1) * 10;
    const mx = (sx + tx) / 2, my = (sy + ty) / 2 + (nt.bow !== undefined ? nt.bow : i % 2 ? 46 : -46);
    // la flecha acaba un poco antes del punto, que se rodea con un círculo a mano
    const ex = tx + (sx - tx) * 0.04, ey = ty + (sy - ty) * 0.04;
    if (s.ring !== false) g += `<ellipse cx="${tx}" cy="${ty}" rx="17" ry="12" fill="none" stroke="${RED}" stroke-width="2.6" transform="rotate(-14 ${tx} ${ty})"/>`;
    g += `<path d="M${sx},${sy} Q${mx},${my} ${ex + (sx > tx ? 14 : -14)},${ey}" fill="none" stroke="${RED}" stroke-width="2.8" stroke-linecap="round" marker-end="url(#ah)"/>`;
  });

  // sello de marca
  const bx = s.side === "L" ? colX : colEnd - 255;
  g += `<g transform="rotate(-8 ${bx + 34} 642)"><image x="${bx}" y="606" width="68" height="68" xlink:href="data:image/png;base64,${logo}" filter="url(#ssh)"/></g>
   <text x="${bx + 82}" y="636" font-family="Caveat" font-weight="700" font-size="32" fill="${INK}">Vínculo</text>
   <text x="${bx + 82}" y="662" font-family="IM FELL English" font-style="italic" font-size="17" fill="${INK}">Pet Journal · WoW: Forever</text>`;

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${W}" height="${H}">${g}</svg>`;
  const img = new Resvg(svg, { font: { fontFiles: fonts, loadSystemFonts: false } }).render().asPng();
  fs.writeFileSync(path.join(out, s.out + ".png"), img);
  console.log(s.file, img.length);
}
