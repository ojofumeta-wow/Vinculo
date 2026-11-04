// Convierte logo/logo.svg en logo/logo.png (512x512) para CurseForge.
const fs = require("fs");
const path = require("path");
const { Resvg } = require("@resvg/resvg-js");

const dir = path.resolve(__dirname, "..", "logo");
const svg = fs.readFileSync(path.join(dir, "logo.svg"));
for (const size of [512]) {
  const png = new Resvg(svg, { fitTo: { mode: "width", value: size } }).render().asPng();
  fs.writeFileSync(path.join(dir, size === 512 ? "logo.png" : `logo-${size}.png`), png);
  console.log(`logo ${size}px: ${png.length} bytes`);
}
