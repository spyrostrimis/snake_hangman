// Draws all of Embersand's art (v7) and renders it to PNG with sharp.
// Terrain tiles are drawn pixel by pixel; everything else is SVG.
// Run: node art_src/make_art.js <sharp module dir> [output dir]
// Writes <out>/<sprite>/<frame>.png and <out>/manifest.json (size and origin of each sprite).
// Everything here is original art made for Embersand.
const path = require("path");
const fs = require("fs");
const sharp = require(process.argv[2] || "sharp");
const OUT = process.argv[3] || path.join(__dirname, "png");
fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(OUT, { recursive: true });

const manifest = [];
const jobs = [];
const svgDoc = (w, h, body) =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><defs>${DEFS}</defs>${body}</svg>`;

/** frames: SVG body strings, or {raw: Buffer} RGBA images of size w x h. */
function sprite(name, frames, w, h, xo, yo) {
  const dir = path.join(OUT, name);
  fs.mkdirSync(dir, { recursive: true });
  frames.forEach((f, i) => {
    const file = path.join(dir, `${i}.png`);
    const img = typeof f === "string"
      ? sharp(Buffer.from(svgDoc(w, h, f)))
      : sharp(f.raw, { raw: { width: w, height: h, channels: 4 } });
    jobs.push(img.png().toFile(file));
  });
  manifest.push({ name, frames: frames.length, w, h, xo: xo ?? 0, yo: yo ?? 0 });
}

function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// ---------- Palette ----------
const K = {
  out: "#1b1714", dark: "#3a3833", mid: "#6d6a62", light: "#a9a497", hi: "#d8d2c2",
  track: "#2a2724", tread: "#55504a",
  team: "#ff00ff", teamD: "#a000a0", // magenta is swapped for the side's colour by sh_team
  glass: "#9fe8ff", lumen: "#5ff2ff", lumenMid: "#1fb4cc", lumenDark: "#0d5c70",
  khaki: "#8f8160", khakiD: "#5e5440", concrete: "#8e8a80", concreteD: "#5f5b53", hazard: "#e8b923",
};

const DEFS = `
<filter id="shadow" x="-50%" y="-50%" width="200%" height="200%"><feColorMatrix type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.42 0"/></filter>
<radialGradient id="glowC"><stop offset="0" stop-color="#e8ffff"/><stop offset="0.35" stop-color="${K.lumen}" stop-opacity="0.8"/><stop offset="1" stop-color="${K.lumen}" stop-opacity="0"/></radialGradient>
<radialGradient id="glowY"><stop offset="0" stop-color="#fffbe0"/><stop offset="0.4" stop-color="#ffd84a" stop-opacity="0.9"/><stop offset="1" stop-color="#ff9a2a" stop-opacity="0"/></radialGradient>
<radialGradient id="soft"><stop offset="0" stop-color="#fff" stop-opacity="1"/><stop offset="0.5" stop-color="#fff" stop-opacity="0.6"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>
<radialGradient id="scorch"><stop offset="0" stop-color="#000" stop-opacity="0.55"/><stop offset="0.6" stop-color="#000" stop-opacity="0.3"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>
<radialGradient id="metalDome" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#f2eee4"/><stop offset="0.5" stop-color="#a9a497"/><stop offset="1" stop-color="#4a4740"/></radialGradient>
<linearGradient id="cyl" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#55524b"/><stop offset="0.35" stop-color="#c9c4b6"/><stop offset="1" stop-color="#4a4740"/></linearGradient>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2b1d3f"/><stop offset="0.45" stop-color="#8a3f4f"/><stop offset="0.75" stop-color="#e2804a"/><stop offset="1" stop-color="#f7c27a"/></linearGradient>
<linearGradient id="cameoBg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a2a40"/><stop offset="0.55" stop-color="#9a5a48"/><stop offset="0.56" stop-color="#c88a52"/><stop offset="1" stop-color="#7a4e2c"/></linearGradient>
`;

// ---------- Terrain (dual grid: each tile sits on the corner of four map cells) ----------
// Tile 0 is empty; tiles 1..16 are rock masks 0..15 (TL=1, TR=2, BR=4, BL=8); 17..19 extra sand; 20..22 extra rock.
function tileNoise(seed, cells) {
  const r = rng(seed);
  const g = [];
  for (let i = 0; i < cells * cells; i++) g.push(r());
  const sm = (t) => t * t * (3 - 2 * t);
  return (x, y) => {
    const fx = (x / 32) * cells, fy = (y / 32) * cells;
    const ix = Math.floor(fx), iy = Math.floor(fy);
    const tx = sm(fx - ix), ty = sm(fy - iy);
    const v = (i, j) => g[(((j % cells) + cells) % cells) * cells + (((i % cells) + cells) % cells)];
    const a = v(ix, iy) + (v(ix + 1, iy) - v(ix, iy)) * tx;
    const b = v(ix, iy + 1) + (v(ix + 1, iy + 1) - v(ix, iy + 1)) * tx;
    return a + (b - a) * ty;
  };
}
const edgeN1 = tileNoise(11, 4), edgeN2 = tileNoise(12, 8), shadeN = tileNoise(13, 4), rippleN = tileNoise(14, 2);
const edgeNoise = (x, y) => (edgeN1(x, y) - 0.5) * 0.22 + (edgeN2(x, y) - 0.5) * 0.12;

function terrainTile(mask, seed) {
  const R = 9; // corner rounding radius in pixels
  const corner = (x, y) => { // which cell owns point (x, y) in this tile's 4-cell neighbourhood
    const right = x >= 16, bottom = y >= 16;
    const bit = bottom ? (right ? 4 : 8) : (right ? 2 : 1);
    return (mask & bit) ? 1 : 0;
  };
  const field = new Float32Array(34 * 34);
  for (let py = -1; py < 33; py++) for (let px = -1; px < 33; px++) {
    let s = 0, n = 0;
    for (let dy = -R; dy <= R; dy++) for (let dx = -R; dx <= R; dx++) {
      if (dx * dx + dy * dy > R * R) continue;
      s += corner(px + 0.5 + dx, py + 0.5 + dy); n++;
    }
    let f = s / n;
    if (f > 0.02 && f < 0.98) f += edgeNoise(px + 0.5, py + 0.5);
    field[(py + 1) * 34 + (px + 1)] = f;
  }
  const F = (x, y) => field[(y + 1) * 34 + (x + 1)];
  const r = rng(seed * 977 + mask * 31 + 5);
  const buf = Buffer.alloc(32 * 32 * 4);
  for (let y = 0; y < 32; y++) for (let x = 0; x < 32; x++) {
    const f = F(x, y);
    const dfdy = F(x, y + 1) - F(x, y - 1);
    const dfdx = F(x + 1, y) - F(x - 1, y);
    const sh = shadeN(x + 0.5, y + 0.5) - 0.5;
    let c;
    if (f >= 0.5) {
      // rock: dark granular stone
      const g = r();
      c = [96, 84, 76];
      if (g < 0.18) c = [70, 61, 56]; else if (g > 0.86) c = [126, 112, 100]; else if (g > 0.97) c = [150, 136, 120];
      c = c.map((v) => v + sh * 26);
      if (f < 0.58) { // rim: lit from the top left
        const lit = -(dfdx + dfdy);
        c = lit > 0 ? [150, 134, 116] : [58, 50, 46];
      }
    } else {
      // sand with ripples
      const rip = Math.sin(2 * Math.PI * (x / 32 + (2 * y) / 32) + 6.28 * rippleN(x, y));
      c = [216, 156, 96];
      if (rip > 0.82) c = [194, 136, 80]; else if (rip < -0.9) c = [232, 176, 116];
      const g = r();
      if (g < 0.06) c = [184, 128, 74]; else if (g > 0.95) c = [236, 186, 128];
      c = c.map((v) => v + sh * 22);
      if (f > 0.3 && dfdy < -0.002) { // cliff face below a rock edge
        const k = Math.min(1, (f - 0.3) / 0.2);
        c = c.map((v, i) => v * (1 - k) + [86, 70, 60][i] * k);
      } else if (f > 0.36) {
        c = c.map((v) => v * 0.82);
      }
    }
    const o = (y * 32 + x) * 4;
    buf[o] = Math.max(0, Math.min(255, c[0])); buf[o + 1] = Math.max(0, Math.min(255, c[1]));
    buf[o + 2] = Math.max(0, Math.min(255, c[2])); buf[o + 3] = 255;
  }
  return buf;
}
{
  const tiles = [Buffer.alloc(32 * 32 * 4)];
  for (let m = 0; m < 16; m++) tiles.push(terrainTile(m, 1));
  for (let v = 0; v < 3; v++) tiles.push(terrainTile(0, 2 + v));
  for (let v = 0; v < 3; v++) tiles.push(terrainTile(15, 2 + v));
  while (tiles.length < 24) tiles.push(Buffer.alloc(32 * 32 * 4));
  const W = 8 * 32, H = 3 * 32, sheet = Buffer.alloc(W * H * 4);
  tiles.forEach((t, i) => {
    const ox = (i % 8) * 32, oy = Math.floor(i / 8) * 32;
    for (let y = 0; y < 32; y++) t.copy(sheet, ((oy + y) * W + ox) * 4, y * 128, y * 128 + 128);
  });
  sprite("spr_terrain", [{ raw: sheet }], W, H, 0, 0);
}

// ---------- Lumen crystal fields (tileset: 0 empty, 1-2 thin, 3-4 medium, 5-6 rich, 7 vent) ----------
function shard(x, y, len, ang, wdt) {
  const a = (ang * Math.PI) / 180, c = Math.cos(a), s = Math.sin(a);
  const p = (u, v) => `${(x + u * c - v * s).toFixed(2)},${(y + u * s + v * c).toFixed(2)}`;
  return `<polygon points="${p(0, -wdt)} ${p(len * 0.75, -wdt * 0.8)} ${p(len, 0)} ${p(len * 0.75, wdt * 0.8)} ${p(0, wdt)}" fill="${K.lumenMid}" stroke="${K.lumenDark}" stroke-width="0.7"/>
  <polygon points="${p(0, -wdt * 0.5)} ${p(len * 0.7, -wdt * 0.4)} ${p(len * 0.95, 0)} ${p(0, 0)}" fill="${K.lumen}"/>`;
}
function lumenCell(density, seed) {
  // No stain under the crystals, so neighbouring cells blend into one field.
  const r = rng(seed);
  let s = "";
  const n = [4, 7, 11][density];
  const pts = [];
  for (let i = 0; i < n; i++) pts.push([3 + r() * 26, 4 + r() * 25]);
  pts.sort((a, b) => a[1] - b[1]);
  for (const [x, y] of pts) s += `<ellipse cx="${x}" cy="${y + 1}" rx="4" ry="2.4" fill="${K.lumenDark}" opacity="0.35"/><circle cx="${x}" cy="${y - 2}" r="${3 + density}" fill="url(#glowC)" opacity="0.45"/>`;
  for (const [x, y] of pts) s += shard(x, y, 3 + r() * (3 + density * 1.5), -40 - r() * 100, 0.9 + r() * 0.8);
  return s;
}
{
  const cells = [""];
  for (let d = 0; d < 3; d++) for (let v = 0; v < 2; v++) cells.push(lumenCell(d, 40 + d * 7 + v));
  let vent = `<circle cx="16" cy="18" r="14" fill="url(#glowC)" opacity="0.6"/><ellipse cx="16" cy="22" rx="10" ry="5" fill="#2a2420" stroke="${K.lumenDark}"/>`;
  [[-70, 13], [-95, 15], [-115, 11], [-50, 9], [-135, 8]].forEach(([a, l], i) => (vent += shard(16 + (i - 2) * 2, 22, l, a, 1.8)));
  cells.push(vent);
  sprite("spr_lumen", [cells.map((c, i) => `<g transform="translate(${i * 32},0)">${c}</g>`).join("")], 32 * 8, 32, 0, 0);
}

// ---------- Crags (impassable boulder piles; tileset 0 empty, 1-4 variants) ----------
function crag(seed) {
  const r = rng(seed);
  let s = `<ellipse cx="17" cy="19" rx="15" ry="12" fill="#000" opacity="0.25"/>`;
  const rocks = [];
  for (let i = 0; i < 5; i++) rocks.push([5 + r() * 22, 6 + r() * 20, 5 + r() * 6]);
  rocks.sort((a, b) => a[1] - b[1]);
  for (const [x, y, rad] of rocks) {
    let pts = [];
    const k = 6 + Math.floor(r() * 3);
    for (let j = 0; j < k; j++) {
      const a = (j / k) * Math.PI * 2, rr = rad * (0.75 + r() * 0.35);
      pts.push([x + Math.cos(a) * rr, y + Math.sin(a) * rr * 0.85]);
    }
    const P = pts.map((p) => p.map((v) => v.toFixed(1)).join(",")).join(" ");
    s += `<polygon points="${P}" fill="#4d4038" stroke="${K.out}" stroke-width="0.9"/>`;
    s += `<polygon points="${pts.filter((p) => p[1] <= y).map((p) => `${p[0].toFixed(1)},${(p[1] + (y - p[1]) * 0.25).toFixed(1)}`).join(" ")}" fill="#7d6a5a"/>`;
    s += `<circle cx="${x - rad * 0.3}" cy="${y - rad * 0.4}" r="${rad * 0.25}" fill="#a08a72" opacity="0.8"/>`;
  }
  return s;
}
sprite("spr_crag", [["", crag(1), crag(2), crag(3), crag(4)].map((c, i) => `<g transform="translate(${i * 32},0)">${c}</g>`).join("")], 160, 32, 0, 0);

// ---------- Units (32 rotations, facing right at frame 0, counter-clockwise like GameMaker) ----------
const tracks = (x, y, w, h) => {
  let s = `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="1" fill="${K.track}" stroke="${K.out}" stroke-width="0.7"/>`;
  for (let tx = x + 1.5; tx < x + w - 0.5; tx += 2.5) s += `<line x1="${tx}" y1="${y + 0.6}" x2="${tx}" y2="${y + h - 0.6}" stroke="${K.tread}" stroke-width="0.7"/>`;
  return s;
};
const U = {
  trooper: { size: 16, body: () => `
    <rect x="-4.2" y="-2.4" width="2.6" height="4.8" rx="0.8" fill="${K.khakiD}" stroke="${K.out}" stroke-width="0.5"/>
    <ellipse cx="0" cy="0" rx="2.6" ry="3.7" fill="${K.khaki}" stroke="${K.out}" stroke-width="0.6"/>
    <rect x="0.4" y="1" width="6.2" height="1.1" fill="${K.out}"/>
    <circle cx="0.4" cy="0" r="2.1" fill="${K.team}" stroke="${K.out}" stroke-width="0.5"/>` },
  rocketeer: { size: 16, body: () => `
    <rect x="-4.2" y="-2.4" width="2.6" height="4.8" rx="0.8" fill="${K.khakiD}" stroke="${K.out}" stroke-width="0.5"/>
    <ellipse cx="0" cy="0" rx="2.6" ry="3.7" fill="${K.khaki}" stroke="${K.out}" stroke-width="0.6"/>
    <rect x="-4.5" y="-3.6" width="10.5" height="2.2" rx="0.6" fill="#5d6b3a" stroke="${K.out}" stroke-width="0.5"/>
    <rect x="5.4" y="-3.8" width="1.4" height="2.6" fill="${K.dark}"/>
    <circle cx="0.4" cy="0.4" r="2.1" fill="${K.team}" stroke="${K.out}" stroke-width="0.5"/>` },
  buggy: { size: 24, body: () => `
    ${[[-7.5, -7.4], [3, -7.4], [-7.5, 4.4], [3, 4.4]].map(([x, y]) => `<rect x="${x}" y="${y}" width="4.6" height="3" rx="0.8" fill="${K.track}" stroke="${K.out}" stroke-width="0.6"/>`).join("")}
    <polygon points="-8,-4.6 6,-4.6 9,-2 9,2 6,4.6 -8,4.6" fill="${K.light}" stroke="${K.out}" stroke-width="0.8"/>
    <polygon points="-7,-3.6 5.5,-3.6 7.6,-1.6 -7,-1.6" fill="${K.hi}" opacity="0.6"/>
    <rect x="-3.5" y="-2.2" width="3.4" height="4.4" rx="0.8" fill="${K.team}" stroke="${K.out}" stroke-width="0.5"/>
    <rect x="-4.5" y="-3.2" width="6.5" height="6.4" fill="none" stroke="${K.dark}" stroke-width="0.9"/>
    <rect x="1.5" y="-0.7" width="9" height="1.4" fill="${K.out}"/>` },
  tank: { size: 32, body: () => `
    ${tracks(-11, -8.2, 22, 4.6)}${tracks(-11, 3.6, 22, 4.6)}
    <rect x="-9.5" y="-5" width="19" height="10" rx="1.6" fill="${K.mid}" stroke="${K.out}" stroke-width="0.8"/>
    <rect x="-8.6" y="-4.2" width="17" height="3" rx="1" fill="${K.light}" opacity="0.6"/>
    <rect x="-9" y="-3.2" width="3.6" height="6.4" fill="${K.team}" stroke="${K.out}" stroke-width="0.4"/>
    <polygon points="9.5,-5 11.2,-3 11.2,3 9.5,5" fill="${K.dark}" stroke="${K.out}" stroke-width="0.6"/>`,
    turret: () => `
    <rect x="2" y="-1" width="11" height="2" fill="${K.dark}" stroke="${K.out}" stroke-width="0.6"/>
    <rect x="11.5" y="-1.4" width="2.4" height="2.8" fill="${K.out}"/>
    <circle cx="0" cy="0" r="5" fill="${K.light}" stroke="${K.out}" stroke-width="0.8"/>
    <circle cx="-0.6" cy="-0.6" r="3.2" fill="${K.hi}" opacity="0.5"/>
    <circle cx="-1.6" cy="0.6" r="1.4" fill="${K.team}" stroke="${K.out}" stroke-width="0.4"/>` },
  launcher: { size: 32, body: () => `
    ${tracks(-10.5, -7.6, 21, 4.2)}${tracks(-10.5, 3.4, 21, 4.2)}
    <rect x="-9" y="-4.6" width="18" height="9.2" rx="1.2" fill="${K.light}" stroke="${K.out}" stroke-width="0.8"/>
    <rect x="5" y="-3.6" width="3.6" height="7.2" rx="0.6" fill="${K.glass}" stroke="${K.out}" stroke-width="0.5"/>
    <rect x="-8.5" y="-4.2" width="3" height="8.4" fill="${K.team}"/>`,
    turret: () => `
    <rect x="-6" y="-5.4" width="10.5" height="10.8" rx="1" fill="${K.dark}" stroke="${K.out}" stroke-width="0.8"/>
    <rect x="-6" y="-5.4" width="2.2" height="10.8" fill="${K.team}"/>
    ${[-3.6, -1.2, 1.2, 3.6].map((y) => `<rect x="-3" y="${y - 0.9}" width="8.4" height="1.8" fill="${K.mid}"/><circle cx="5.6" cy="${y}" r="1.05" fill="#efe6d4" stroke="${K.out}" stroke-width="0.4"/>`).join("")}` },
  heavy: { size: 32, body: () => `
    ${tracks(-12.5, -10.4, 25, 5.6)}${tracks(-12.5, 4.8, 25, 5.6)}
    <rect x="-11.5" y="-6.4" width="23" height="12.8" rx="2" fill="${K.mid}" stroke="${K.out}" stroke-width="0.9"/>
    <rect x="-10.5" y="-5.4" width="21" height="3.6" rx="1" fill="${K.light}" opacity="0.55"/>
    <rect x="-11" y="-4" width="2.6" height="8" fill="${K.team}"/><rect x="-7.4" y="-4" width="1.4" height="8" fill="${K.team}"/>
    <polygon points="11.5,-6.4 13.4,-4 13.4,4 11.5,6.4" fill="${K.dark}" stroke="${K.out}" stroke-width="0.6"/>`,
    turret: () => `
    <rect x="3" y="-3.4" width="12" height="2" fill="${K.dark}" stroke="${K.out}" stroke-width="0.6"/>
    <rect x="3" y="1.4" width="12" height="2" fill="${K.dark}" stroke="${K.out}" stroke-width="0.6"/>
    <rect x="-6.4" y="-6" width="12" height="12" rx="3" fill="${K.light}" stroke="${K.out}" stroke-width="0.9"/>
    <rect x="-5.4" y="-5" width="7" height="5" rx="2" fill="${K.hi}" opacity="0.5"/>
    <rect x="-5.6" y="-2" width="3" height="4" fill="${K.team}" stroke="${K.out}" stroke-width="0.4"/>` },
  harvester: { size: 40, body: () => `
    ${tracks(-15, -10.5, 28, 5)}${tracks(-15, 5.5, 28, 5)}
    <rect x="-14.5" y="-7.5" width="19" height="15" rx="1.2" fill="${K.mid}" stroke="${K.out}" stroke-width="0.9"/>
    <rect x="-12.5" y="-5.5" width="15" height="11" fill="${K.dark}"/>
    ${[[-10, -2], [-7, 2], [-3, -3], [-1, 1.5], [-9, 3]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="1.4" fill="${K.lumenMid}"/>`).join("")}
    <rect x="4" y="-6.5" width="8.5" height="13" rx="1" fill="${K.team}" stroke="${K.out}" stroke-width="0.8"/>
    <rect x="9.4" y="-4.8" width="2.2" height="9.6" fill="${K.glass}" stroke="${K.out}" stroke-width="0.4"/>
    <polygon points="12.5,-9.5 16.8,-10.5 16.8,10.5 12.5,9.5" fill="${K.dark}" stroke="${K.out}" stroke-width="0.8"/>
    ${[-8, -4, 0, 4, 8].map((y) => `<line x1="16.8" y1="${y}" x2="18.6" y2="${y}" stroke="${K.light}" stroke-width="1"/>`).join("")}` },
};
const ROT = 32;
function rotFrames(size, draw) {
  const h = size / 2, frames = [];
  for (let i = 0; i < ROT; i++) {
    const a = (-i * 360) / ROT;
    frames.push(`<g transform="translate(${h},${h})"><g transform="translate(1.4,1.6) rotate(${a})" filter="url(#shadow)">${draw()}</g><g transform="rotate(${a})">${draw()}</g></g>`);
  }
  return frames;
}
function rotFramesNoShadow(size, draw) {
  const h = size / 2, frames = [];
  for (let i = 0; i < ROT; i++) frames.push(`<g transform="translate(${h},${h}) rotate(${(-i * 360) / ROT})">${draw()}</g>`);
  return frames;
}
for (const [k, u] of Object.entries(U)) {
  sprite(`spr_${k}`, rotFrames(u.size, u.body), u.size, u.size, u.size / 2, u.size / 2);
  if (u.turret) sprite(`spr_${k}_turret`, rotFrames(u.size, u.turret), u.size, u.size, u.size / 2, u.size / 2);
}

// ---------- Buildings (drawn on a concrete pad, lit from the top left) ----------
const pad = (w, h) => {
  let s = `<rect x="1" y="1" width="${w - 2}" height="${h - 2}" rx="2" fill="${K.concrete}" stroke="#3d3a35" stroke-width="1.2"/>`;
  for (let x = 16; x < w - 1; x += 16) s += `<line x1="${x}" y1="2" x2="${x}" y2="${h - 2}" stroke="#77736a" stroke-width="0.8"/>`;
  for (let y = 16; y < h - 1; y += 16) s += `<line x1="2" y1="${y}" x2="${w - 2}" y2="${y}" stroke="#77736a" stroke-width="0.8"/>`;
  s += `<line x1="2.5" y1="2.5" x2="${w - 3}" y2="2.5" stroke="#b5b0a4" stroke-width="1"/>`;
  return s;
};
const box = (x, y, w, h, top, depth, front) =>
  `<rect x="${x}" y="${y + h - depth}" width="${w}" height="${depth}" fill="${front || K.mid}" stroke="${K.out}" stroke-width="0.9"/>` +
  `<rect x="${x}" y="${y}" width="${w}" height="${h - depth}" fill="${top}" stroke="${K.out}" stroke-width="0.9"/>`;
const lightDot = (x, y, c = "#ffd84a") => `<circle cx="${x}" cy="${y}" r="2.2" fill="url(#glowY)"/><circle cx="${x}" cy="${y}" r="0.9" fill="${c}"/>`;
const hazardStripe = (x, y, w, h) => {
  let s = `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${K.hazard}"/>`;
  for (let i = -h; i < w; i += 5) s += `<polygon points="${x + Math.max(0, i)},${y + Math.max(0, -i) * 0} ${x + Math.min(w, i + 2.5)},${y} ${x + Math.min(w, i + 2.5 + h)},${y + h} ${x + Math.min(w, i + h)},${y + h}" fill="${K.out}" opacity="0.85"/>`;
  return `<g clip-path="none">${s}</g>`;
};
const B = {
  yard: { w: 64, h: 64, draw: () => `${pad(64, 64)}
    ${box(5, 12, 54, 44, "#b9b4a6", 11)}
    <rect x="5" y="12" width="54" height="5" fill="${K.team}" stroke="${K.out}" stroke-width="0.8"/>
    <circle cx="22" cy="31" r="10.5" fill="url(#metalDome)" stroke="${K.out}" stroke-width="1"/>
    <rect x="38" y="22" width="16" height="4" fill="${K.team}"/><rect x="38" y="29" width="16" height="4" fill="${K.team}"/>
    <rect x="26" y="47" width="12" height="9" fill="${K.out}"/>${hazardStripe(26, 45, 12, 2)}
    <line x1="46" y1="38" x2="58" y2="5" stroke="${K.dark}" stroke-width="2.6"/><line x1="58" y1="5" x2="44" y2="4" stroke="${K.dark}" stroke-width="1.8"/>
    <line x1="45" y1="4" x2="45" y2="12" stroke="${K.out}" stroke-width="0.8"/>
    ${lightDot(10, 50)}${lightDot(54, 50)}` },
  power: { w: 64, h: 64, draw: () => `${pad(64, 64)}
    ${[20, 44].map((cx) => `<rect x="${cx - 10}" y="18" width="20" height="34" fill="url(#cyl)" stroke="${K.out}" stroke-width="0.9"/>
      <rect x="${cx - 10}" y="36" width="20" height="5" fill="${K.team}" stroke="${K.out}" stroke-width="0.6"/>
      <ellipse cx="${cx}" cy="18" rx="10" ry="5" fill="#c9c4b6" stroke="${K.out}" stroke-width="0.9"/>
      <ellipse cx="${cx}" cy="18" rx="6" ry="3" fill="url(#glowY)"/><ellipse cx="${cx}" cy="18" rx="2.5" ry="1.3" fill="#fffbe0"/>`).join("")}
    <rect x="28" y="44" width="8" height="5" fill="${K.dark}" stroke="${K.out}" stroke-width="0.6"/>${lightDot(32, 57)}` },
  refinery: { w: 96, h: 64, draw: () => `${pad(96, 64)}
    ${[16, 40].map((cx) => `<rect x="${cx - 11}" y="14" width="22" height="26" fill="url(#cyl)" stroke="${K.out}" stroke-width="0.9"/>
      <ellipse cx="${cx}" cy="14" rx="11" ry="5.5" fill="#cfcabd" stroke="${K.out}" stroke-width="0.9"/>
      <rect x="${cx - 11}" y="28" width="22" height="3" fill="${K.team}"/>`).join("")}
    <path d="M16 40 V48 H60 M40 40 V46" stroke="${K.lumenMid}" stroke-width="2.4" fill="none"/>
    <path d="M16 40 V48 H60 M40 40 V46" stroke="${K.lumen}" stroke-width="0.8" fill="none"/>
    ${box(54, 6, 36, 32, "#b9b4a6", 9)}
    <rect x="58" y="10" width="12" height="4" fill="${K.team}"/><rect x="74" y="10" width="12" height="4" fill="${K.team}"/>
    <rect x="60" y="17" width="24" height="8" fill="${K.dark}" stroke="${K.out}" stroke-width="0.6"/>
    <rect x="62" y="19" width="20" height="4" fill="${K.lumenMid}"/><rect x="62" y="19" width="20" height="1.6" fill="${K.lumen}"/>
    <rect x="64" y="40" width="32" height="23" fill="#6f6b62" stroke="${K.out}" stroke-width="0.8"/>
    ${hazardStripe(64, 40, 32, 2.5)}
    <polygon points="76,46 84,46 84,43 90,50 84,57 84,54 76,54" fill="${K.hazard}" opacity="0.8"/>
    ${lightDot(6, 58)}${lightDot(60, 58, K.lumen)}` },
  barracks: { w: 64, h: 64, draw: () => `${pad(64, 64)}
    <rect x="6" y="16" width="52" height="30" rx="3" fill="#7d7a52" stroke="${K.out}" stroke-width="0.9"/>
    <line x1="6" y1="28" x2="58" y2="28" stroke="#5d5a3a" stroke-width="1.4"/>
    ${[14, 24, 34, 44, 54].map((x) => `<line x1="${x}" y1="17" x2="${x}" y2="45" stroke="#68653f" stroke-width="0.8"/>`).join("")}
    <rect x="6" y="38" width="52" height="10" fill="#5d5a3a" stroke="${K.out}" stroke-width="0.9"/>
    <rect x="27" y="39" width="10" height="9" fill="${K.out}"/>
    ${[8, 15, 22, 42, 49, 56].map((x) => `<ellipse cx="${x}" cy="54" rx="3.8" ry="2.4" fill="#b3a07a" stroke="${K.out}" stroke-width="0.6"/>`).join("")}
    <line x1="10" y1="4" x2="10" y2="18" stroke="${K.out}" stroke-width="1.2"/>
    <polygon points="10.6,4.5 22,7 10.6,10" fill="${K.team}" stroke="${K.out}" stroke-width="0.5"/>` },
  factory: { w: 96, h: 64, draw: () => `${pad(96, 64)}
    <rect x="4" y="6" width="88" height="36" fill="#b5b0a3" stroke="${K.out}" stroke-width="0.9"/>
    ${Array.from({ length: 10 }, (_, i) => `<line x1="${8 + i * 9}" y1="7" x2="${8 + i * 9}" y2="41" stroke="#8d897e" stroke-width="1.2"/>`).join("")}
    <rect x="4" y="18" width="88" height="5" fill="${K.team}" stroke="${K.out}" stroke-width="0.6"/>
    <rect x="4" y="40" width="88" height="16" fill="${K.mid}" stroke="${K.out}" stroke-width="0.9"/>
    <rect x="33" y="42" width="30" height="14" fill="#262420" stroke="${K.out}" stroke-width="0.8"/>
    ${[45, 48, 51, 54].map((y) => `<line x1="34" y1="${y}" x2="62" y2="${y}" stroke="#3d3a35" stroke-width="0.8"/>`).join("")}
    ${hazardStripe(33, 40.5, 30, 2)}
    <rect x="76" y="2" width="8" height="12" fill="${K.dark}" stroke="${K.out}" stroke-width="0.8"/>
    ${lightDot(10, 48)}${lightDot(86, 48)}` },
  radar: { w: 64, h: 64, draw: () => `${pad(64, 64)}
    ${box(9, 28, 46, 28, "#b9b4a6", 9)}
    <rect x="9" y="28" width="46" height="4" fill="${K.team}"/>
    <rect x="28" y="20" width="8" height="12" fill="${K.dark}" stroke="${K.out}" stroke-width="0.8"/>
    <rect x="14" y="36" width="10" height="5" fill="${K.lumenDark}"/><rect x="40" y="36" width="10" height="5" fill="${K.lumenDark}"/>
    ${lightDot(12, 52, "#ff5040")}` },
  gun: { w: 32, h: 32, draw: () => `
    <polygon points="9,2 23,2 30,9 30,23 23,30 9,30 2,23 2,9" fill="${K.concrete}" stroke="${K.out}" stroke-width="1"/>
    <polygon points="10,5 22,5 27,10 27,22 22,27 10,27 5,22 5,10" fill="${K.mid}" stroke="#3d3a35" stroke-width="0.8"/>
    <rect x="3" y="14" width="3" height="4" fill="${K.team}"/><rect x="26" y="14" width="3" height="4" fill="${K.team}"/>` },
  rocket: { w: 32, h: 32, draw: () => `
    ${box(2, 2, 28, 28, "#a49f92", 6)}
    <rect x="2" y="2" width="28" height="3" fill="${K.team}"/>
    <rect x="7" y="7" width="18" height="13" fill="${K.mid}" stroke="#3d3a35" stroke-width="0.8"/>` },
};
for (const [k, b] of Object.entries(B)) sprite(`spr_b_${k}`, [b.draw()], b.w, b.h, 0, 0);

// Turret heads and the radar dish
sprite("spr_gun_head", rotFrames(32, () => `
  <rect x="2" y="-1.2" width="12" height="2.4" fill="${K.dark}" stroke="${K.out}" stroke-width="0.6"/>
  <circle cx="0" cy="0" r="6" fill="${K.light}" stroke="${K.out}" stroke-width="0.9"/>
  <circle cx="-0.8" cy="-0.8" r="3.6" fill="${K.hi}" opacity="0.5"/><circle cx="-2" cy="0" r="1.6" fill="${K.team}"/>`), 32, 32, 16, 16);
sprite("spr_rocket_head", rotFrames(32, () => `
  <rect x="-5" y="-6" width="11" height="12" rx="1.5" fill="${K.light}" stroke="${K.out}" stroke-width="0.9"/>
  <rect x="-5" y="-6" width="3" height="12" fill="${K.team}"/>
  ${[-3, 3].map((y) => `<rect x="-1" y="${y - 1.6}" width="10" height="3.2" fill="${K.dark}" stroke="${K.out}" stroke-width="0.5"/><circle cx="9" cy="${y}" r="1.3" fill="#efe6d4"/>`).join("")}`), 32, 32, 16, 16);
{
  const frames = [];
  for (let i = 0; i < 16; i++) {
    const a = (i / 16) * Math.PI * 2, c = Math.cos(a), s = Math.sin(a);
    const rx = 3 + 11 * Math.abs(c);
    const face = c >= 0 ? "#d8d2c2" : "#7a766c";
    frames.push(`<g transform="translate(16,16)">
      <ellipse cx="1.5" cy="2" rx="${rx}" ry="10" fill="#000" opacity="0.3"/>
      <ellipse cx="0" cy="0" rx="${rx}" ry="10" fill="${face}" stroke="${K.out}" stroke-width="0.9"/>
      <ellipse cx="${s * 2}" cy="0" rx="${rx * 0.55}" ry="6" fill="none" stroke="${K.mid}" stroke-width="0.8"/>
      <line x1="0" y1="0" x2="${c * 7}" y2="-3" stroke="${K.out}" stroke-width="1"/><circle cx="${c * 7}" cy="-3" r="1.2" fill="#ff5040"/></g>`);
  }
  sprite("spr_radar_dish", frames, 32, 32, 16, 16);
}
// Walls: 16 frames by neighbour mask (N=1, E=2, S=4, W=8)
{
  const frames = [];
  for (let m = 0; m < 16; m++) {
    const seg = (x, y, w, h) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="#b0aa9b"/>`;
    const fr = (x, y, w, h) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="#77726a"/>`;
    let s = `<rect x="9" y="9" width="14" height="16" fill="#77726a" stroke="${K.out}" stroke-width="0.8"/>`;
    if (m & 1) s += `<rect x="9" y="0" width="14" height="12" fill="#b0aa9b" stroke="${K.out}" stroke-width="0.8"/>`;
    if (m & 2) s += `<rect x="20" y="9" width="12" height="16" fill="#77726a" stroke="${K.out}" stroke-width="0.8"/>`;
    if (m & 4) s += `<rect x="9" y="20" width="14" height="12" fill="#77726a" stroke="${K.out}" stroke-width="0.8"/>`;
    if (m & 8) s += `<rect x="0" y="9" width="12" height="16" fill="#77726a" stroke="${K.out}" stroke-width="0.8"/>`;
    s += seg(9.5, 9.5, 13, 11);
    if (m & 1) s += seg(9.5, 0, 13, 12);
    if (m & 2) s += seg(20, 9.5, 12, 11);
    if (m & 4) s += seg(9.5, 18, 13, 14);
    if (m & 8) s += seg(0, 9.5, 12, 11);
    s += `<line x1="10" y1="10.5" x2="22" y2="10.5" stroke="#d6d0c0" stroke-width="0.8"/>`;
    frames.push(s);
  }
  sprite("spr_b_wall", frames, 32, 32, 0, 0);
}

// ---------- Effects ----------
{
  const frames = [];
  for (let i = 0; i < 10; i++) {
    const t = i / 9, r = rng(77);
    let s = `<g transform="translate(24,24)">`;
    for (let j = 0; j < 7; j++) {
      const a = r() * 6.28, d = r() * 9 * (0.4 + t), rad = (4 + r() * 5) * (0.5 + t * 1.1);
      const col = t < 0.15 ? "#fffbe0" : t < 0.35 ? "#ffd84a" : t < 0.55 ? "#ff8a2a" : t < 0.75 ? "#b8401c" : "#4a3a34";
      const op = t < 0.75 ? 1 : 1 - (t - 0.75) * 3.2;
      s += `<circle cx="${(Math.cos(a) * d).toFixed(1)}" cy="${(Math.sin(a) * d - t * 6).toFixed(1)}" r="${rad.toFixed(1)}" fill="${col}" opacity="${op.toFixed(2)}"/>`;
    }
    if (t < 0.5) s += `<circle cx="0" cy="0" r="${4 + t * 8}" fill="#fffbe0" opacity="${1 - t * 2}"/>`;
    frames.push(s + "</g>");
  }
  sprite("spr_explosion", frames, 48, 48, 24, 24);
}
sprite("spr_smoke", [`<circle cx="8" cy="8" r="8" fill="url(#soft)"/>`], 16, 16, 8, 8);
sprite("spr_flare", [`<circle cx="4" cy="4" r="4" fill="url(#glowY)"/>`], 8, 8, 4, 4);
sprite("spr_scorch", [`<ellipse cx="24" cy="24" rx="23" ry="20" fill="url(#scorch)"/>`], 48, 48, 24, 24);
sprite("spr_crater", [0, 1, 2].map((v) => {
  const r = rng(90 + v);
  return `<ellipse cx="14" cy="10" rx="${10 + r() * 3}" ry="${6 + r() * 2}" fill="#3e2d20" opacity="0.65"/>
    <ellipse cx="14" cy="11.5" rx="${7 + r() * 2}" ry="${3.5 + r()}" fill="#24190f" opacity="0.6"/>
    <path d="M5 13 Q14 ${18 + r() * 2} 23 13" stroke="#e8b47a" stroke-width="1" fill="none" opacity="0.6"/>`;
}), 28, 20, 14, 10);
sprite("spr_rocket", [`<polygon points="0,1.5 2,0 2,5 0,3.5" fill="${K.dark}"/><rect x="1.5" y="1.4" width="6" height="2.2" fill="#efe6d4" stroke="${K.out}" stroke-width="0.4"/><polygon points="7.5,1.4 10,2.5 7.5,3.6" fill="#d03a2a"/>`], 10, 5, 5, 2.5);
sprite("spr_shell", [`<circle cx="3" cy="3" r="3" fill="url(#glowY)"/><circle cx="3" cy="3" r="1.2" fill="#fffbe0"/>`], 6, 6, 3, 3);

// ---------- Cursors (GUI, 32 x 32, centred; 0 pointer, 1 move, 2 attack, 3 harvest/enter, 4 no, 5 sell, 6 repair) ----------
{
  const o = `stroke="#000" stroke-width="3.2" fill="none" stroke-linejoin="round"`;
  const arrow = (c) => `<path d="M16 16 L16 30 L19.5 26.5 L22.5 32 L25 30.8 L22 25.4 L27 25 Z" fill="${c}" stroke="#000" stroke-width="1.4" stroke-linejoin="round"/>`;
  const quad = (c) => { let s = ""; for (let i = 0; i < 4; i++) s += `<g transform="rotate(${i * 90} 16 16)"><polygon points="16,3 21,9 11,9" fill="${c}" stroke="#000" stroke-width="1.2"/></g>`; return s; };
  const cross = (c) => `<circle cx="16" cy="16" r="9" ${o}/><circle cx="16" cy="16" r="9" stroke="${c}" stroke-width="1.8" fill="none"/>
    <path d="M16 2 V10 M16 22 V30 M2 16 H10 M22 16 H30" ${o}/><path d="M16 2 V10 M16 22 V30 M2 16 H10 M22 16 H30" stroke="${c}" stroke-width="1.8"/><circle cx="16" cy="16" r="1.5" fill="${c}"/>`;
  const bracket = (c) => { const p = "M5 11 V5 H11 M21 5 H27 V11 M27 21 V27 H21 M11 27 H5 V21"; return `<path d="${p}" ${o}/><path d="${p}" stroke="${c}" stroke-width="2" fill="none"/>`; };
  const no = `<circle cx="16" cy="16" r="10" ${o}/><circle cx="16" cy="16" r="10" stroke="#ff3a2a" stroke-width="2.2" fill="none"/><path d="M9 9 L23 23" stroke="#000" stroke-width="4"/><path d="M9 9 L23 23" stroke="#ff3a2a" stroke-width="2.2"/>`;
  const sell = `<circle cx="16" cy="16" r="11" fill="#000" opacity="0.5"/><text x="16" y="23" text-anchor="middle" font-family="Arial" font-weight="bold" font-size="20" fill="#ffd84a" stroke="#000" stroke-width="1">$</text>`;
  const wrench = `<path d="M9 25 L19 15 A5.5 5.5 0 1 1 22 10 L19.5 12.5 L20.5 14.5 L22.5 15.5 L25 13 A5.5 5.5 0 0 1 19 18 L9 28 Z" fill="#9fe86a" stroke="#000" stroke-width="1.4"/>`;
  sprite("spr_cursor", [arrow("#f2eee4"), quad("#6aff5a"), cross("#ff4a3a"), bracket(K.lumen), no, sell, wrench], 32, 32, 16, 16);
}

// ---------- Cameos for the build sidebar (116 x 64, drawn 1:1 in the GUI) ----------
function cameo(inner) {
  return `<rect width="116" height="64" fill="url(#cameoBg)"/><circle cx="92" cy="14" r="9" fill="#f3d3a0" opacity="0.8"/>
    <ellipse cx="92" cy="14" rx="16" ry="3" fill="none" stroke="#f3d3a0" stroke-width="1" opacity="0.6"/>${inner}
    <rect x="0.5" y="0.5" width="115" height="63" fill="none" stroke="#000" stroke-width="1"/>`;
}
const cameos = {};
for (const [k, b] of Object.entries(B)) {
  const s = Math.min(100 / b.w, 56 / b.h, 1.7);
  cameos[k] = cameo(`<g transform="translate(${58 - (b.w * s) / 2},${34 - (b.h * s) / 2}) scale(${s})">${b.draw()}${k === "gun" ? `<g transform="translate(16,16) rotate(150)">${""}</g>` : ""}</g>`);
}
cameos.wall = cameo(`${[0, 1, 2].map((i) => `<g transform="translate(${16 + i * 28},16) scale(0.9)"><rect x="0" y="4" width="32" height="28" fill="#77726a" stroke="#000"/><rect x="0" y="4" width="32" height="18" fill="#b0aa9b" stroke="#000"/></g>`).join("")}`);
for (const [k, u] of Object.entries(U)) {
  const sc = { 16: 3.4, 24: 2.6, 32: 2.1, 40: 1.6 }[u.size];
  const draw = () => u.body() + (u.turret ? u.turret() : "");
  cameos[k] = cameo(`<g transform="translate(58,36) scale(${sc}) rotate(160)"><g transform="translate(1,1.4)" filter="url(#shadow)">${draw()}</g>${draw()}</g>`);
}
cameos.trooper = cameo([[-14, 4], [0, -4], [14, 4]].map(([x, y]) => `<g transform="translate(${58 + x},${36 + y}) scale(2.6) rotate(-100)"><g filter="url(#shadow)" transform="translate(0.8,0.8)">${U.trooper.body()}</g>${U.trooper.body()}</g>`).join(""));
cameos.gun = cameo(`<g transform="translate(38,10) scale(1.4)">${B.gun.draw()}<g transform="translate(16,16) rotate(160)"><circle r="6" fill="${K.light}" stroke="${K.out}"/><rect x="2" y="-1.2" width="12" height="2.4" fill="${K.dark}" stroke="${K.out}" stroke-width="0.6"/><circle cx="-2" r="1.6" fill="${K.team}"/></g></g>`);
cameos.rocket = cameo(`<g transform="translate(38,10) scale(1.4)">${B.rocket.draw()}<g transform="translate(16,16) rotate(160)"><rect x="-5" y="-6" width="11" height="12" rx="1.5" fill="${K.light}" stroke="${K.out}"/><rect x="-5" y="-6" width="3" height="12" fill="${K.team}"/>${[-3, 3].map((y) => `<rect x="-1" y="${y - 1.6}" width="10" height="3.2" fill="${K.dark}"/>`).join("")}</g></g>`);
cameos.radar = cameo(`<g transform="translate(36,4) scale(0.9)">${B.radar.draw()}<g transform="translate(32,22)"><ellipse rx="12" ry="10" fill="#d8d2c2" stroke="${K.out}"/><ellipse rx="6" ry="6" fill="none" stroke="${K.mid}"/></g></g>`);
const CAMEO_ORDER = ["power", "refinery", "barracks", "factory", "radar", "gun", "rocket", "wall", "trooper", "rocketeer", "buggy", "tank", "launcher", "heavy", "harvester", "yard"];
sprite("spr_cameo", CAMEO_ORDER.map((k) => cameos[k]), 116, 64, 0, 0);
fs.writeFileSync(path.join(OUT, "cameo_order.txt"), CAMEO_ORDER.join(","));

// ---------- Advisor portrait (K-7, a survey drone) ----------
const advisor = (blink) => `
  <rect width="240" height="240" fill="#1a1620"/>
  <g stroke="#2a2433" stroke-width="1">${Array.from({ length: 12 }, (_, i) => `<line x1="0" y1="${i * 20 + 10}" x2="240" y2="${i * 20 + 10}"/>`).join("")}</g>
  <circle cx="120" cy="120" r="96" fill="url(#glowY)" opacity="0.18"/>
  <ellipse cx="124" cy="214" rx="60" ry="10" fill="#000" opacity="0.4"/>
  <path d="M120 40 L120 18" stroke="#6d6a62" stroke-width="4"/><circle cx="120" cy="16" r="6" fill="#ff5040"/>
  <path d="M46 116 L18 92 L14 126 Z" fill="#6d6a62" stroke="#111" stroke-width="3"/>
  <path d="M194 116 L222 92 L226 126 Z" fill="#6d6a62" stroke="#111" stroke-width="3"/>
  <circle cx="120" cy="118" r="78" fill="url(#metalDome)" stroke="#111" stroke-width="4"/>
  <path d="M60 150 Q120 196 180 150" stroke="#4a4740" stroke-width="5" fill="none"/>
  <rect x="64" y="70" width="112" height="14" rx="6" fill="#d9a066" stroke="#111" stroke-width="3"/>
  <circle cx="120" cy="124" r="38" fill="#2a2620" stroke="#111" stroke-width="4"/>
  <circle cx="120" cy="124" r="28" fill="${blink ? "#4a3a20" : "url(#glowY)"}"/>
  ${blink ? `<rect x="92" y="120" width="56" height="7" rx="3" fill="#ffd84a"/>` : `<circle cx="120" cy="124" r="12" fill="#fffbe0"/><circle cx="112" cy="116" r="5" fill="#fff"/>`}
  <g fill="#ffd84a" opacity="0.8">${[0, 1, 2, 3, 4].map((i) => `<rect x="${86 + i * 15}" y="170" width="9" height="5" rx="1"/>`).join("")}</g>`;
sprite("spr_advisor", [advisor(false), advisor(true)], 240, 240, 0, 0);

// ---------- Mission pictures (480 x 270) and the title background ----------
function dunes(w, h, top, cols, seed) {
  const r = rng(seed);
  let s = "";
  cols.forEach((c, i) => {
    const y0 = top + i * ((h - top) / cols.length) * 0.8;
    let d = `M0 ${h} L0 ${y0}`;
    const ph = r() * 6, ph2 = r() * 6;
    for (let x = 0; x <= w; x += 8) d += ` L${x} ${(y0 + Math.sin(x / (w / 3) + ph) * 14 + Math.sin(x / (w / 9) + ph2) * 5).toFixed(1)}`;
    s += `<path d="${d} L${w} ${h} Z" fill="${c}"/>`;
  });
  return s;
}
const ringPlanet = (x, y, r) => `<circle cx="${x}" cy="${y}" r="${r}" fill="#f0c890"/><circle cx="${x + r * 0.3}" cy="${y - r * 0.2}" r="${r}" fill="#000" opacity="0.18"/>
  <ellipse cx="${x}" cy="${y}" rx="${r * 1.9}" ry="${r * 0.35}" fill="none" stroke="#f6dcb0" stroke-width="${r * 0.12}" opacity="0.8" transform="rotate(-12 ${x} ${y})"/>`;
const silhouetteHarvester = (x, y, s, c) => `<g transform="translate(${x},${y}) scale(${s})" fill="${c}"><rect x="-30" y="-22" width="44" height="22"/><rect x="14" y="-28" width="16" height="28"/><polygon points="30,-24 40,-28 40,0 30,0"/><rect x="-34" y="0" width="76" height="8" rx="4"/></g>`;
const tankSil = (x, y, s, c) => `<g transform="translate(${x},${y}) scale(${s})" fill="${c}"><rect x="-22" y="-10" width="44" height="12" rx="3"/><rect x="-12" y="-20" width="22" height="11" rx="4"/><rect x="8" y="-17" width="26" height="4"/><rect x="-24" y="0" width="48" height="8" rx="4"/></g>`;
const towerSil = (x, y, s, c) => `<g transform="translate(${x},${y}) scale(${s})" fill="${c}"><rect x="-6" y="-60" width="12" height="60"/><rect x="-14" y="-70" width="28" height="12"/><rect x="-2" y="-90" width="4" height="22"/><rect x="-20" y="-8" width="40" height="8"/></g>`;
const scene1 = `<rect width="480" height="270" fill="url(#sky)"/>${ringPlanet(360, 70, 34)}
  ${dunes(480, 270, 170, ["#b9764a", "#d08a52", "#e2a466"], 3)}
  <g transform="translate(200,110) rotate(-8)"><polygon points="-50,0 40,-8 60,0 40,10 -50,8" fill="#3a3440"/><polygon points="-20,-4 10,-16 30,-6" fill="#4a4450"/>
  <circle cx="-30" cy="14" r="8" fill="url(#glowY)"/><circle cx="20" cy="16" r="8" fill="url(#glowY)"/></g>
  <path d="M170 128 L160 220 M220 126 L232 222" stroke="#ffd84a" stroke-width="3" opacity="0.35"/>
  ${[0, 1, 2].map((i) => `<rect x="${150 + i * 26}" y="${222 - (i % 2) * 6}" width="20" height="14" fill="#5a4a3a" stroke="#2a2018"/>`).join("")}`;
const scene2 = `<rect width="480" height="270" fill="url(#sky)"/>${ringPlanet(90, 60, 22)}
  <path d="M0 270 L0 150 L80 120 L160 140 L260 100 L340 130 L480 110 L480 270 Z" fill="#4a3c34"/>
  <path d="M0 270 L0 190 L120 170 L240 186 L360 160 L480 176 L480 270 Z" fill="#6a564a"/>
  ${tankSil(150, 168, 1.1, "#1c1818")}${tankSil(250, 150, 0.9, "#1c1818")}${tankSil(330, 176, 1.2, "#1c1818")}
  ${[[60, 230], [90, 240], [400, 235], [430, 225]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="14" fill="url(#glowC)"/>${shard(x, y, 16, -80, 3)}${shard(x + 4, y, 12, -50, 2.5)}`).join("")}`;
const scene3 = `<rect width="480" height="270" fill="#2a1416"/><rect width="480" height="270" fill="url(#sky)" opacity="0.5"/>
  ${[[120, 80, 60], [300, 60, 80], [420, 100, 50]].map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="#3a2a2a" opacity="0.7"/>`).join("")}
  ${towerSil(100, 200, 1, "#140c0c")}${towerSil(380, 196, 1.2, "#140c0c")}
  <circle cx="240" cy="190" r="40" fill="url(#glowY)"/><circle cx="300" cy="170" r="24" fill="url(#glowY)"/>
  ${dunes(480, 270, 200, ["#3a2420", "#5a3426"], 9)}${tankSil(200, 240, 1.3, "#0c0808")}`;
sprite("spr_mission_pic", [scene1, scene2, scene3], 480, 270, 0, 0);
const title = `<rect width="1280" height="720" fill="url(#sky)"/>
  ${Array.from({ length: 60 }, (_, i) => { const r = rng(500 + i); return `<circle cx="${r() * 1280}" cy="${r() * 260}" r="${0.6 + r() * 1.4}" fill="#fff" opacity="${0.3 + r() * 0.6}"/>`; }).join("")}
  ${ringPlanet(980, 170, 90)}
  ${dunes(1280, 720, 420, ["#8a4a3a", "#b0663e", "#cf8550", "#e3a266"], 21)}
  ${towerSil(220, 520, 1.6, "#2a1a1a")}${towerSil(300, 540, 1.1, "#2a1a1a")}
  <rect x="160" y="500" width="200" height="40" fill="#2a1a1a"/>${lightDot(180, 505)}${lightDot(340, 505)}
  ${silhouetteHarvester(820, 600, 2.2, "#24160f")}
  <ellipse cx="940" cy="620" rx="70" ry="12" fill="url(#glowC)" opacity="0.7"/>
  ${[[900, 615], [940, 622], [975, 612]].map(([x, y]) => shard(x, y, 22, -75, 4)).join("")}`;
sprite("spr_title_bg", [title], 1280, 720, 0, 0);

Promise.all(jobs).then(() => {
  fs.writeFileSync(path.join(OUT, "manifest.json"), JSON.stringify(manifest, null, 1));
  console.log(`Rendered ${jobs.length} frames in ${manifest.length} sprites.`);
}).catch((e) => { console.error(e); process.exit(1); });
