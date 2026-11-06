// Brings the PNGs made by make_art.js into the GameMaker project.
//
//   node art_src/import_art.js --refresh [spr_name ...]
//       Copies new frames over sprites that already exist (same frame count), and refreshes the
//       tileset images. No .yy files change. Use this after editing make_art.js.
//
//   node art_src/import_art.js [spr_name ...] > import.txt
//   npx @gamemaker/gm-cli resourcetool script import.txt
//       Writes a resource-tool script that creates the sprites (first import, or new sprites).
const path = require("path");
const fs = require("fs");
const PNG = path.join(__dirname, "png");
const ROOT = path.join(__dirname, "..");
const manifest = JSON.parse(fs.readFileSync(path.join(PNG, "manifest.json"), "utf8"));
const only = process.argv.filter((a) => a.startsWith("spr_"));
const pick = manifest.filter((s) => !only.length || only.includes(s.name));
// Tilesets show the sprite's image as-is (no borders), saved as output_tileset.png.
const TILESETS = { spr_terrain: "ts_terrain", spr_lumen: "ts_lumen", spr_crag: "ts_crag" };

if (process.argv.includes("--refresh")) {
  for (const s of pick) {
    const dir = path.join(ROOT, "sprites", s.name);
    if (!fs.existsSync(dir)) { console.error(`skip ${s.name}: not in the project yet`); continue; }
    for (let i = 0; i < s.frames; i++) {
      const src = path.join(PNG, s.name, `${i}.png`);
      fs.copyFileSync(src, path.join(dir, `frame${i}.png`));
      fs.copyFileSync(src, path.join(dir, "layers", `frame${i}`, "layer1.png"));
    }
    if (TILESETS[s.name]) fs.copyFileSync(path.join(PNG, s.name, "0.png"), path.join(ROOT, "tilesets", TILESETS[s.name], "output_tileset.png"));
    console.error(`refreshed ${s.name}`);
  }
} else {
  const lines = [];
  for (const s of pick) {
    lines.push(`RESOURCE CREATE TYPE=sprite NAME=${s.name} FOLDER=Sprites`);
    for (let i = 0; i < s.frames; i++) lines.push(`SPRITE ADDFRAME NAME=${s.name} PATH=art_src/png/${s.name}/${i}.png`);
    if (s.xo || s.yo) {
      lines.push(`RESOURCE SET EXPR=${s.name}.origin VALUE=Custom`);
      lines.push(`RESOURCE SET EXPR=${s.name}.sequence.xorigin VALUE=${Math.round(s.xo)}`);
      lines.push(`RESOURCE SET EXPR=${s.name}.sequence.yorigin VALUE=${Math.round(s.yo)}`);
    }
  }
  process.stdout.write(lines.join("\n") + "\n");
}
