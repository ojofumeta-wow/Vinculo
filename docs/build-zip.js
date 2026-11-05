// Genera el zip para CurseForge (solo Vinculo.toc, forward slashes, comprimido). El zip hecho con `tar` fue RECHAZADO por CurseForge.
// Uso: instala jszip en una carpeta temporal (npm i jszip) y ejecuta: JSZIP=<ruta>/node_modules/jszip node docs/build-zip.js dist/Vinculo-X.Y.Z.zip
const fs = require("fs"), path = require("path");
const JSZip = require(process.env.JSZIP || "jszip");
const root = path.join(__dirname, "..", "Vinculo");
const skip = new Set(["Vinculo_Mists.toc", "Vinculo_Vanilla.toc"]);
const zip = new JSZip();
const date = new Date();
function walk(dir, rel) {
  for (const name of fs.readdirSync(dir).sort()) {
    if (rel === "Vinculo" && skip.has(name)) continue;
    const full = path.join(dir, name), r = rel + "/" + name;
    if (fs.statSync(full).isDirectory()) walk(full, r);
    else zip.file(r, fs.readFileSync(full), { date, createFolders: false, compression: "DEFLATE" });
  }
}
walk(root, "Vinculo");
zip.generateAsync({ type: "nodebuffer", compression: "DEFLATE", platform: "UNIX", streamFiles: false }).then(buf => {
  fs.writeFileSync(process.argv[2], buf);
  console.log("ok", buf.length);
});
