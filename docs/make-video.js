// Monta el clip de dist/video/vinculo-demo.mp4 dentro del marco de pergamino con subtítulos a mano.
// Uso: FFMPEG=<ruta a ffmpeg.exe> node docs/make-video.js   -> dist/video/vinculo-demo-marco.mp4 y .gif
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");
const { Resvg } = require("../_luatest/node_modules/@resvg/resvg-js");

const root = path.resolve(__dirname, "..");
const dir = path.join(root, "dist", "video");
const tmp = path.join(dir, "_tmp");
fs.mkdirSync(tmp, { recursive: true });
const FF = process.env.FFMPEG;
const fonts = ["IMFell.ttf", "Caveat.ttf"].map(f => path.join(root, "Vinculo", "Media", "Fonts", f));
const logo = fs.readFileSync(path.join(root, "logo", "logo.png")).toString("base64");
const INK = "#3a1f0c", RED = "#8a2410", W = 1280, H = 720, SPEED = Number(process.env.SPEED || 0.6), K = 1 / SPEED, DUR = 7.5 * K;
const VX = 140, VY = 128, VW = 1000, VH = 457; // posición del vídeo dentro del marco

const defs = `<defs>
 <radialGradient id="par" cx="50%" cy="45%" r="75%"><stop offset="0" stop-color="#f3e4bb"/><stop offset="0.7" stop-color="#e2c994"/><stop offset="1" stop-color="#b88f55"/></radialGradient>
 <radialGradient id="burn" cx="50%" cy="50%" r="72%"><stop offset="0.62" stop-color="#2a1205" stop-opacity="0"/><stop offset="1" stop-color="#2a1205" stop-opacity="0.55"/></radialGradient>
 <linearGradient id="leather" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a2a14"/><stop offset="1" stop-color="#26130a"/></linearGradient>
 <filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="3" seed="4"/><feColorMatrix type="matrix" values="0 0 0 0 0.30  0 0 0 0 0.18  0 0 0 0 0.06  0 0 0 1.1 -0.45"/></filter>
 <filter id="stain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.011" numOctaves="3" seed="9"/><feColorMatrix type="matrix" values="0 0 0 0 0.45  0 0 0 0 0.27  0 0 0 0 0.08  0 0 0 1.4 -0.55"/></filter>
 <filter id="sh" x="-15%" y="-15%" width="130%" height="140%"><feDropShadow dx="2" dy="9" stdDeviation="9" flood-color="#2a1205" flood-opacity="0.55"/></filter>
 <filter id="ssh" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="1" dy="4" stdDeviation="3" flood-color="#2a1205" flood-opacity="0.5"/></filter>
</defs>`;

const page = `<rect width="${W}" height="${H}" fill="url(#leather)"/><rect width="${W}" height="${H}" filter="url(#grain)" opacity="0.5"/>
<rect x="26" y="26" width="${W - 52}" height="${H - 52}" rx="12" fill="url(#par)" filter="url(#sh)"/>
<rect x="26" y="26" width="${W - 52}" height="${H - 52}" rx="12" filter="url(#stain)" opacity="0.5"/>
<rect x="26" y="26" width="${W - 52}" height="${H - 52}" rx="12" filter="url(#grain)" opacity="0.35"/>
<rect x="26" y="26" width="${W - 52}" height="${H - 52}" rx="12" fill="url(#burn)"/>
<rect x="40" y="40" width="${W - 80}" height="${H - 80}" rx="8" fill="none" stroke="#7a5a30" stroke-width="1.6" stroke-dasharray="9 6" opacity="0.55"/>`;

const render = (body, file) => {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${W}" height="${H}">${body}</svg>`;
  fs.writeFileSync(file, new Resvg(svg, { font: { fontFiles: fonts, loadSystemFonts: false } }).render().asPng());
};

// fondo: marco de papel donde irá el vídeo, cintas, título y sello
const bg = defs + page + `
<text x="86" y="92" font-family="Caveat" font-weight="700" font-size="62" fill="${INK}">Vínculo</text>
<text x="290" y="90" font-family="IM FELL English" font-style="italic" font-size="26" fill="${INK}">a journal for your hunter pet</text>
<path d="M86,106 q40,-7 80,0 t80,0 t80,0" fill="none" stroke="${RED}" stroke-width="3" stroke-linecap="round"/>
<rect x="${VX - 12}" y="${VY - 12}" width="${VW + 24}" height="${VH + 24}" fill="#f6ecd2" filter="url(#sh)"/>
<rect x="${VX - 50}" y="${VY - 20}" width="92" height="30" fill="#e9d7a0" fill-opacity="0.85" transform="rotate(-36 ${VX - 4} ${VY - 5})" filter="url(#ssh)"/>
<rect x="${VX + VW - 42}" y="${VY - 20}" width="92" height="30" fill="#e9d7a0" fill-opacity="0.85" transform="rotate(34 ${VX + VW + 4} ${VY - 5})" filter="url(#ssh)"/>
<g transform="rotate(-8 1200 90)"><image x="1166" y="56" width="68" height="68" xlink:href="data:image/png;base64,${logo}" filter="url(#ssh)"/></g>`;
render(bg, path.join(tmp, "bg.png"));

// subtítulos: [texto, inicio, fin] en segundos del clip
const caps = [
  ["21 achievements, one for every moment", 0.0, 0.9],
  ["The story of every adventure", 0.9, 2.1],
  ["A bestiary to plan your next tame", 2.1, 4.1],
  ["One click and it shows on the map", 4.1, 7.5],
];
caps.forEach(c => { c[1] *= K; c[2] *= K; }); // los tiempos de arriba son los del clip a velocidad normal
caps.forEach(([t], i) => render(`<text x="${W / 2}" y="668" text-anchor="middle" font-family="Caveat" font-size="46" fill="${RED}">${t}</text>`, path.join(tmp, `c${i}.png`)));

const inputs = ["-loop", "1", "-t", String(DUR), "-i", path.join(tmp, "bg.png"), "-i", path.join(dir, "vinculo-demo.mp4")];
caps.forEach((_, i) => inputs.push("-loop", "1", "-t", String(DUR), "-i", path.join(tmp, `c${i}.png`)));
let f = `[1:v]setpts=PTS/${SPEED},minterpolate=fps=30:mi_mode=mci:mc_mode=aobmc:vsbmc=1,scale=${VW}:${VH},fade=t=in:st=0:d=0.4,fade=t=out:st=${DUR - 0.4}:d=0.4[v];[0:v][v]overlay=${VX}:${VY}[b0]`;
caps.forEach(([, a, b], i) => {
  f += `;[${i + 2}:v]format=rgba,fade=t=in:st=${a}:d=0.25:alpha=1,fade=t=out:st=${b - 0.25}:d=0.25:alpha=1[c${i}];[b${i}][c${i}]overlay=0:0[b${i + 1}]`;
});
const last = `b${caps.length}`;
const run = a => { const r = spawnSync(FF, a, { encoding: "utf8" }); if (r.status) { console.error(r.stderr); process.exit(1); } };
const mp4 = path.join(dir, "vinculo-demo-marco.mp4");
run(["-y", "-loglevel", "error", ...inputs, "-filter_complex", f, "-map", `[${last}]`, "-t", String(DUR), "-r", "30", "-c:v", "libx264", "-crf", "20", "-preset", "slow", "-pix_fmt", "yuv420p", "-movflags", "+faststart", mp4]);
run(["-y", "-loglevel", "error", "-i", mp4, "-vf", "fps=10,scale=800:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=160:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=3", path.join(dir, "vinculo-demo-marco.gif")]);
fs.rmSync(tmp, { recursive: true, force: true });
console.log("ok");
