// Draws all of v5's art as SVG and renders it to PNG with sharp.
// Run: node art_src/make_art.js <sharp module dir> <output dir>
// Everything here is original art made for Snake Hangman: Jungle Jam.
const path = require("path");
const fs = require("fs");
const sharp = require(process.argv[2] || "sharp");
const OUT = process.argv[3] || path.join(__dirname, "png");
fs.mkdirSync(OUT, { recursive: true });

const svg = (w, h, body, defs = "") =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><defs>${defs}</defs>${body}</svg>`;
const jobs = [];
const save = (name, w, h, body, defs) =>
  jobs.push(sharp(Buffer.from(svg(w, h, body, defs))).png().toFile(path.join(OUT, name + ".png")));

// ---------- Colours ----------
const C = {
  grass: "#55c42a", grassLight: "#9be84a", grassDark: "#2c8a16", grassLine: "#185a0c",
  dirt: "#6e3f1c", stone: "#b9773f", stoneLight: "#e0a86a", stoneDark: "#7a4720", mortar: "#4a2a10",
  snake: "#5cc433", snakeDark: "#1f6b12", snakeSpot: "#3f9a22", belly: "#e2f27a",
};

// ---------- Tiles (32 x 32; tile 0 is empty) ----------
function stones(seed) {
  // A cobble pattern that stays inside the tile, so tiles join cleanly.
  const sets = [
    [[8, 9, 7, 6], [23, 8, 7, 6], [7, 23, 6, 7], [21, 22, 9, 7], [16, 15, 4, 3]],
    [[9, 7, 8, 5], [24, 12, 6, 7], [10, 21, 8, 7], [24, 26, 6, 4], [3, 14, 3, 4]],
  ];
  return sets[seed % 2].map(([x, y, rx, ry]) =>
    `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="url(#st)" stroke="${C.mortar}" stroke-width="1.5"/>` +
    `<ellipse cx="${x - rx * 0.3}" cy="${y - ry * 0.35}" rx="${rx * 0.4}" ry="${ry * 0.3}" fill="${C.stoneLight}" opacity="0.7"/>`
  ).join("");
}
const stoneGrad = `<linearGradient id="st" x1="0" y1="0" x2="0.6" y2="1"><stop offset="0" stop-color="${C.stoneLight}"/><stop offset="0.5" stop-color="${C.stone}"/><stop offset="1" stop-color="${C.stoneDark}"/></linearGradient>
<linearGradient id="gr" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${C.grassLight}"/><stop offset="0.6" stop-color="${C.grass}"/><stop offset="1" stop-color="${C.grassDark}"/></linearGradient>
<linearGradient id="log" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d89a52"/><stop offset="1" stop-color="#7a4416"/></linearGradient>
<linearGradient id="rock" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#c6c3d8"/><stop offset="1" stop-color="#6c6886"/></linearGradient>`;
const dirt = (seed) => `<rect width="32" height="32" fill="${C.dirt}"/>${stones(seed)}`;
const grassTop = (left, right) => {
  // A grass band with blades hanging over, and rounded ends where the ground stops.
  let blades = "";
  for (let x = 1; x < 32; x += 4) blades += `<path d="M${x} 9 L${x + 2} ${13 + ((x * 7) % 4)} L${x + 4} 9 Z" fill="${C.grass}" stroke="${C.grassLine}" stroke-width="0.8"/>`;
  const l = left ? `<circle cx="2" cy="7" r="6" fill="url(#gr)" stroke="${C.grassLine}" stroke-width="1.2"/>` : "";
  const r = right ? `<circle cx="30" cy="7" r="6" fill="url(#gr)" stroke="${C.grassLine}" stroke-width="1.2"/>` : "";
  return `<rect x="${left ? 2 : 0}" y="1" width="${32 - (left ? 2 : 0) - (right ? 2 : 0)}" height="10" fill="url(#gr)"/>
    <line x1="${left ? 2 : 0}" y1="1" x2="${right ? 30 : 32}" y2="1" stroke="${C.grassLine}" stroke-width="1.5"/>${blades}${l}${r}
    <path d="M4 4 q3 -2 6 0 M16 3 q3 -2 6 0" stroke="#d6ff9a" stroke-width="1.2" fill="none" opacity="0.8"/>`;
};
const tiles = [
  "",                                                   // 0 empty
  dirt(0) + grassTop(false, false),                     // 1 grass
  dirt(0),                                              // 2 dirt A
  dirt(1),                                              // 3 dirt B
  dirt(1) + grassTop(true, false),                      // 4 grass, left end
  dirt(0) + grassTop(false, true),                      // 5 grass, right end
  dirt(1) + `<rect x="0" y="22" width="32" height="10" fill="#3a1e08" opacity="0.55"/>
    <path d="M6 32 q2 -6 0 -10 M18 32 q-2 -5 1 -9 M27 32 q1 -4 -1 -8" stroke="#2a1404" stroke-width="2" fill="none"/>`, // 6 dirt underside
  `<rect x="0" y="2" width="32" height="11" rx="5" fill="url(#log)" stroke="#4a2608" stroke-width="1.5"/>
    <circle cx="5" cy="7.5" r="3" fill="none" stroke="#5a3010" stroke-width="1"/><line x1="11" y1="5" x2="28" y2="5" stroke="#f0c07a" stroke-width="1.2"/>
    <line x1="10" y1="10" x2="24" y2="10" stroke="#5a3010" stroke-width="1"/>`, // 7 log platform (one-way)
  `<rect x="1" y="1" width="30" height="30" rx="4" fill="url(#rock)" stroke="#3c3850" stroke-width="2"/>
    <path d="M8 3 L13 12 L9 18 L15 29 M24 4 L20 13 L26 19" stroke="#3c3850" stroke-width="1.6" fill="none"/>
    <path d="M5 6 L10 5" stroke="#ffffff" stroke-width="1.5" opacity="0.7"/>`, // 8 cracked block (breakable)
  `<path d="M0 32 L4 16 L8 32 L12 16 L16 32 L20 16 L24 32 L28 16 L32 32 Z" fill="url(#rock)" stroke="#33304a" stroke-width="1.5"/>
    <path d="M3 22 L4 17 M11 22 L12 17 M19 22 L20 17 M27 22 L28 17" stroke="#fff" stroke-width="1" opacity="0.8"/>`, // 9 spikes
  dirt(0) + grassTop(true, true),                       // 10 grass, single column
];
// Each tile is clipped to its own 32 x 32 square so rounded grass ends cannot spill into a neighbour.
save("spr_tiles", 32 * tiles.length, 32,
  tiles.map((t, i) => `<g transform="translate(${i * 32},0)" clip-path="url(#cell)">${t}</g>`).join(""),
  stoneGrad + `<clipPath id="cell"><rect x="0" y="0" width="32" height="32"/></clipPath>`);

// ---------- Parallax backgrounds (seamless left to right) ----------
function ridge(w, h, base, amps, periods, phase = 0) {
  // A wavy ridge whose waves all repeat exactly across the width, so the image tiles.
  let d = `M0 ${h} `;
  for (let x = 0; x <= w; x += 8) {
    let y = base;
    amps.forEach((a, i) => (y -= a * Math.sin((x / w) * Math.PI * 2 * periods[i] + phase * (i + 1))));
    d += `L${x} ${y.toFixed(1)} `;
  }
  return d + `L${w} ${h} Z`;
}
save("spr_bg_mountains", 1024, 260,
  `<path d="${ridge(1024, 260, 150, [40, 22, 9], [3, 7, 17], 0.5)}" fill="#3d3a9e"/>
   <path d="${ridge(1024, 260, 175, [26, 14, 6], [4, 9, 23], 1.7)}" fill="#2c2a7e"/>
   <path d="${ridge(1024, 260, 150, [40, 22, 9], [3, 7, 17], 0.5)}" fill="none" stroke="#7b78e0" stroke-width="3" opacity="0.6"/>`);
let trees = "";
for (let i = 0; i < 16; i++) {
  const x = i * 64 + 20 + ((i * 37) % 30);
  const y = 120 - ((i * 53) % 30);
  trees += `<rect x="${x - 3}" y="${y}" width="6" height="${200 - y}" fill="#2d5a20"/>
    <circle cx="${x}" cy="${y}" r="${22 + (i % 3) * 5}" fill="#3f8a2a"/><circle cx="${x - 8}" cy="${y - 6}" r="12" fill="#5aae38"/>`;
}
save("spr_bg_hills", 1024, 200, trees +
  `<path d="${ridge(1024, 200, 140, [22, 10], [2, 5], 0.3)}" fill="#2f7a26"/>
   <path d="${ridge(1024, 200, 160, [16, 8], [3, 8], 2.1)}" fill="#246a1c"/>`);
let clouds = "";
for (let i = 0; i < 6; i++) {
  const x = i * 170 + 60;
  const y = 40 + ((i * 29) % 50);
  clouds += `<g opacity="0.85"><ellipse cx="${x}" cy="${y}" rx="46" ry="16" fill="#ffffff"/><circle cx="${x - 18}" cy="${y - 10}" r="16" fill="#ffffff"/>
    <circle cx="${x + 12}" cy="${y - 14}" r="20" fill="#ffffff"/><ellipse cx="${x}" cy="${y + 6}" rx="44" ry="8" fill="#c8dcff"/></g>`;
}
save("spr_bg_clouds", 1024, 130, clouds);

// ---------- The snake (facing right) ----------
function head(frame) {
  const eye = frame === 1
    ? `<path d="M19 14 q5 4 10 0" stroke="#10300a" stroke-width="2.4" fill="none" stroke-linecap="round"/>`
    : frame === 3
    ? `<path d="M20 10 L28 18 M28 10 L20 18" stroke="#10300a" stroke-width="2.6" stroke-linecap="round"/>`
    : `<ellipse cx="24" cy="14" rx="6.5" ry="7.5" fill="#fff" stroke="#10300a" stroke-width="1.6"/>
       <circle cx="26.5" cy="15" r="3.2" fill="#111"/><circle cx="27.6" cy="13.6" r="1.1" fill="#fff"/>`;
  const mouth = frame === 2
    ? `<path d="M29 22 L40 18 L40 30 Z" fill="#7a0f1c" stroke="${C.snakeDark}" stroke-width="1.5"/>`
    : frame === 3
    ? `<path d="M30 27 q2 -2 4 0 q2 2 4 0" stroke="#10300a" stroke-width="1.6" fill="none"/>`
    : `<path d="M29 26 q5 3 9 -2" stroke="#10300a" stroke-width="1.8" fill="none" stroke-linecap="round"/>`;
  return `<ellipse cx="17" cy="21" rx="15" ry="12.5" fill="${C.snake}" stroke="${C.snakeDark}" stroke-width="2"/>
    <ellipse cx="29" cy="23" rx="10" ry="8" fill="${C.snake}" stroke="${C.snakeDark}" stroke-width="2"/>
    <ellipse cx="22" cy="23" rx="15" ry="9" fill="${C.snake}"/>
    <ellipse cx="22" cy="29" rx="13" ry="4.5" fill="${C.belly}"/>
    <circle cx="10" cy="22" r="2.6" fill="${C.snakeSpot}"/><circle cx="15" cy="15" r="2" fill="${C.snakeSpot}"/>
    <path d="M3 13 Q16 2 30 9" stroke="#6b3a12" stroke-width="3.5" fill="none"/>
    <circle cx="12" cy="8" r="5.2" fill="#7fe3ff" stroke="#c9ccd8" stroke-width="2"/><circle cx="10.5" cy="6.5" r="1.6" fill="#fff"/>
    <circle cx="36" cy="20" r="1" fill="#10300a"/>${eye}${mouth}`;
}
for (let f = 0; f < 4; f++) save("spr_snake_head_" + f, 42, 36, head(f));
save("spr_snake_body", 24, 24,
  `<circle cx="12" cy="12" r="10" fill="${C.snake}" stroke="${C.snakeDark}" stroke-width="2"/>
   <path d="M3 15 Q12 22 21 15 L20 19 Q12 24 4 19 Z" fill="${C.belly}"/>
   <circle cx="9" cy="8" r="2.4" fill="${C.snakeSpot}"/><circle cx="15" cy="10" r="1.6" fill="${C.snakeSpot}"/>
   <path d="M6 6 q3 -3 7 -2" stroke="#c8ff9a" stroke-width="1.5" fill="none"/>`);
save("spr_snake_tail", 18, 18,
  `<circle cx="9" cy="9" r="6.5" fill="${C.snake}" stroke="${C.snakeDark}" stroke-width="2"/><circle cx="7" cy="7" r="1.6" fill="${C.snakeSpot}"/>`);
save("spr_snake_ball", 44, 44,
  `<circle cx="22" cy="22" r="19" fill="${C.snake}" stroke="${C.snakeDark}" stroke-width="2.2"/>
   <path d="M22 22 m-3 0 a3 3 0 1 1 6 0 a7 7 0 1 1 -14 0 a11 11 0 1 1 22 0 a15 15 0 1 1 -30 0" stroke="${C.snakeDark}" stroke-width="2.2" fill="none"/>
   <path d="M8 30 a15 15 0 0 0 28 0" stroke="${C.belly}" stroke-width="3" fill="none" opacity="0.8"/>
   <ellipse cx="30" cy="12" rx="4.5" ry="5" fill="#fff" stroke="#10300a" stroke-width="1.3"/><circle cx="31.5" cy="12.5" r="2" fill="#111"/>
   <circle cx="14" cy="11" r="3.4" fill="#7fe3ff" stroke="#c9ccd8" stroke-width="1.5"/>`);

// ---------- Enemies ----------
function bug(f) {
  const legs = f === 0 ? "M10 22 L6 28 M18 23 L18 29 M26 22 L30 28" : "M10 22 L13 28 M18 23 L15 29 M26 22 L23 28";
  return `<path d="${legs}" stroke="#2a1040" stroke-width="2.5" stroke-linecap="round"/>
    <path d="M3 22 Q4 4 18 4 Q32 4 31 22 Z" fill="#8a3fd1" stroke="#2a1040" stroke-width="2"/>
    <path d="M18 5 L18 22" stroke="#2a1040" stroke-width="1.5"/>
    <ellipse cx="11" cy="10" rx="4" ry="2.5" fill="#d8b0ff" opacity="0.8"/>
    <circle cx="31" cy="18" r="6" fill="#3a1a55" stroke="#1a0828" stroke-width="1.5"/>
    <circle cx="33" cy="16" r="2.2" fill="#fff"/><circle cx="33.6" cy="16.3" r="1" fill="#111"/>
    <path d="M30 12 L35 13.5" stroke="#1a0828" stroke-width="1.6"/>`;
}
save("spr_bug_0", 38, 30, bug(0));
save("spr_bug_1", 38, 30, bug(1));
function bee(f) {
  const wing = f === 0
    ? `<ellipse cx="14" cy="5" rx="7" ry="5" fill="#cdeeff" opacity="0.85" stroke="#6aa0c8"/><ellipse cx="22" cy="4" rx="7" ry="5" fill="#cdeeff" opacity="0.85" stroke="#6aa0c8"/>`
    : `<ellipse cx="13" cy="10" rx="7" ry="3" fill="#cdeeff" opacity="0.85" stroke="#6aa0c8"/><ellipse cx="23" cy="10" rx="7" ry="3" fill="#cdeeff" opacity="0.85" stroke="#6aa0c8"/>`;
  return `${wing}<path d="M4 19 L-1 21 L4 23 Z" fill="#333"/>
    <ellipse cx="18" cy="20" rx="14" ry="11" fill="#ffd21c" stroke="#3a2a00" stroke-width="2"/>
    <path d="M11 10 Q9 20 11 30 M18 9 Q16 20 18 31" stroke="#2a2000" stroke-width="3.5" fill="none"/>
    <circle cx="26" cy="17" r="4.5" fill="#fff" stroke="#3a2a00" stroke-width="1.2"/><circle cx="27.5" cy="17.5" r="2" fill="#111"/>
    <path d="M23 12 L30 13" stroke="#3a2a00" stroke-width="1.8"/><path d="M27 25 q2 2 4 0" stroke="#3a2a00" stroke-width="1.4" fill="none"/>`;
}
save("spr_bee_0", 36, 34, bee(0));
save("spr_bee_1", 36, 34, bee(1));

// ---------- Pickups and props ----------
save("spr_carrot", 22, 32,
  `<path d="M8 6 Q4 0 2 2 M11 6 Q11 -1 14 1 M13 7 Q19 2 20 6" stroke="#2c9a1a" stroke-width="3" fill="none" stroke-linecap="round"/>
   <path d="M5 8 Q11 5 17 8 L12 31 Q11 32 10 31 Z" fill="#ff8a1c" stroke="#9a3e00" stroke-width="1.6"/>
   <path d="M7 13 L11 13 M9 19 L13 18 M10 25 L12 25" stroke="#b85000" stroke-width="1.3"/><path d="M8 10 L9 20" stroke="#ffc07a" stroke-width="1.5"/>`);
save("spr_gem", 22, 22,
  `<path d="M11 1 L21 9 L11 21 L1 9 Z" fill="#ff2e5a" stroke="#7a0020" stroke-width="1.6"/>
   <path d="M1 9 L21 9 M6 9 L11 1 L16 9 L11 21 Z" stroke="#7a0020" stroke-width="1" fill="none"/>
   <path d="M7 8 L11 3 L10 8 Z" fill="#ffd0dc"/>`);
save("spr_orb", 34, 34,
  `<circle cx="17" cy="17" r="15" fill="url(#ob)" stroke="#ffffff" stroke-width="1.8" opacity="0.95"/>
   <path d="M7 12 A11 11 0 0 1 16 5" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round"/>`,
  `<radialGradient id="ob" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#e8fbff"/><stop offset="0.6" stop-color="#64c8ff"/><stop offset="1" stop-color="#1c5fd0"/></radialGradient>`);
save("spr_heart", 20, 18,
  `<path d="M10 17 L2 9 A4.5 4.5 0 0 1 10 3 A4.5 4.5 0 0 1 18 9 Z" fill="#ff3360" stroke="#7a0020" stroke-width="1.6"/>
   <ellipse cx="6" cy="7" rx="2" ry="1.4" fill="#ffd0dc"/>`);
function spring(f) {
  const top = f === 0 ? 4 : 13;
  let coil = "";
  for (let y = top + 5, i = 0; y < 21; y += f === 0 ? 4 : 2.5, i++) coil += `L${i % 2 ? 9 : 23} ${y} `;
  return `<path d="M16 ${top + 5} ${coil}" stroke="#c9ccd8" stroke-width="2.5" fill="none"/>
    <rect x="4" y="21" width="24" height="5" rx="2" fill="#6c6886" stroke="#33304a"/>
    <rect x="2" y="${top}" width="28" height="6" rx="3" fill="#ff3d3d" stroke="#7a0010" stroke-width="1.5"/>`;
}
save("spr_spring_0", 32, 28, spring(0));
save("spr_spring_1", 32, 28, spring(1));
function door(open) {
  const inside = open
    ? `<rect x="11" y="16" width="26" height="46" rx="12" fill="#0c1a2a"/><circle cx="24" cy="36" r="10" fill="#6aff7a" opacity="0.5"/><circle cx="24" cy="36" r="5" fill="#d8ffd8"/>`
    : `<rect x="11" y="16" width="26" height="46" rx="12" fill="#a8642a" stroke="#4a2608" stroke-width="1.5"/>
       <path d="M17 20 L17 60 M24 17 L24 61 M31 20 L31 60" stroke="#6a3a12" stroke-width="1.5"/>
       <rect x="18" y="34" width="12" height="10" rx="2" fill="#ffd21c" stroke="#7a5a00" stroke-width="1.5"/>
       <path d="M20 34 V30 A4 4 0 0 1 28 30 V34" stroke="#7a5a00" stroke-width="2" fill="none"/>`;
  return `<path d="M4 63 V20 A20 20 0 0 1 44 20 V63 Z" fill="url(#rock)" stroke="#33304a" stroke-width="2"/>${inside}
    <path d="M9 24 A15 15 0 0 1 22 8" stroke="#fff" stroke-width="2" fill="none" opacity="0.6"/>`;
}
save("spr_door_0", 48, 64, door(false), stoneGrad);
save("spr_door_1", 48, 64, door(true), stoneGrad);
function flag(up) {
  const f = up ? `<path d="M12 6 L24 11 L12 16 Z" fill="#3ee07a" stroke="#0a6a2a" stroke-width="1.3"/>`
               : `<path d="M12 30 L20 35 L12 40 Z" fill="#ff4a4a" stroke="#7a0010" stroke-width="1.3"/>`;
  return `<rect x="10" y="4" width="3" height="42" fill="#c9ccd8" stroke="#33304a"/><circle cx="11.5" cy="4" r="3" fill="#ffd21c"/>
    <rect x="4" y="44" width="16" height="4" rx="2" fill="#6c6886"/>${f}`;
}
save("spr_flag_0", 26, 48, flag(false));
save("spr_flag_1", 26, 48, flag(true));
save("spr_flower", 16, 24,
  `<path d="M8 24 Q7 16 8 10" stroke="#2c8a16" stroke-width="2" fill="none"/><path d="M8 18 Q3 15 2 17" stroke="#2c8a16" stroke-width="2" fill="none"/>
   <circle cx="8" cy="6" r="3" fill="#ffd21c"/><g fill="#ff5ac8"><circle cx="8" cy="1.8" r="2.4"/><circle cx="12.2" cy="6" r="2.4"/><circle cx="8" cy="10.2" r="2.4"/><circle cx="3.8" cy="6" r="2.4"/></g>
   <circle cx="8" cy="6" r="2.2" fill="#ffd21c"/>`);
save("spr_mushroom", 22, 20,
  `<rect x="8" y="10" width="6" height="10" rx="2" fill="#f4ead2" stroke="#8a7a5a"/>
   <path d="M1 12 Q11 -6 21 12 Z" fill="#e8283a" stroke="#6a0010" stroke-width="1.5"/>
   <circle cx="7" cy="7" r="2" fill="#fff"/><circle cx="14" cy="5" r="1.6" fill="#fff"/><circle cx="16" cy="10" r="1.3" fill="#fff"/>`);
save("spr_bush", 52, 26,
  `<circle cx="12" cy="18" r="10" fill="#3f8a2a"/><circle cx="26" cy="12" r="12" fill="#55a83a"/><circle cx="40" cy="18" r="10" fill="#3f8a2a"/>
   <rect x="2" y="18" width="48" height="8" fill="#3f8a2a"/><circle cx="23" cy="8" r="4" fill="#8ad65a"/>`);
save("spr_vine", 12, 64,
  `<path d="M6 0 Q1 16 6 32 Q11 48 6 64" stroke="#2c8a16" stroke-width="3" fill="none"/>
   <ellipse cx="3" cy="14" rx="3" ry="5" fill="#55c42a"/><ellipse cx="9" cy="38" rx="3" ry="5" fill="#55c42a"/><ellipse cx="3" cy="56" rx="3" ry="4" fill="#55c42a"/>`);

// ---------- Bosses (facing right; frames: 0 stand, 1 move, 2 attack, 3 hurt) ----------
function mouse(f) {
  const grey = "#9a98ac", dark = "#34324a", pink = "#f4a3b8";
  const lean = f === 2 ? -6 : 0;
  const legs = f === 1 ? `<ellipse cx="30" cy="77" rx="9" ry="5" fill="${pink}" stroke="${dark}" stroke-width="2"/><ellipse cx="56" cy="74" rx="9" ry="5" fill="${pink}" stroke="${dark}" stroke-width="2"/>`
                       : `<ellipse cx="32" cy="76" rx="9" ry="5" fill="${pink}" stroke="${dark}" stroke-width="2"/><ellipse cx="54" cy="76" rx="9" ry="5" fill="${pink}" stroke="${dark}" stroke-width="2"/>`;
  const eyes = f === 3
    ? `<path d="M55 24 L61 30 M61 24 L55 30 M65 23 L71 29 M71 23 L65 29" stroke="${dark}" stroke-width="2.5" stroke-linecap="round"/>`
    : `<ellipse cx="58" cy="27" rx="4.5" ry="5.5" fill="#fff" stroke="${dark}" stroke-width="1.5"/><ellipse cx="68" cy="26" rx="4.5" ry="5.5" fill="#fff" stroke="${dark}" stroke-width="1.5"/>
       <circle cx="60" cy="28" r="2.2" fill="#111"/><circle cx="70" cy="27" r="2.2" fill="#111"/>
       <path d="M53 19 L63 23 M73 18 L65 22" stroke="${dark}" stroke-width="3" stroke-linecap="round"/>`;
  const glove = f === 2
    ? `<circle cx="20" cy="40" r="10" fill="#e8283a" stroke="#6a0010" stroke-width="2"/><path d="M16 36 q4 -3 8 0" stroke="#ffb0b8" stroke-width="2" fill="none"/>`
    : `<circle cx="72" cy="56" r="10" fill="#e8283a" stroke="#6a0010" stroke-width="2"/><path d="M68 52 q4 -3 8 0" stroke="#ffb0b8" stroke-width="2" fill="none"/>`;
  return `<g transform="translate(${lean} 0)">
    <path d="M18 60 Q2 56 4 40 Q6 30 12 34" stroke="${pink}" stroke-width="4" fill="none" stroke-linecap="round"/>
    ${legs}
    <ellipse cx="42" cy="56" rx="25" ry="20" fill="${grey}" stroke="${dark}" stroke-width="2.5"/>
    <ellipse cx="47" cy="61" rx="14" ry="11" fill="#dcdbe6"/>
    <circle cx="28" cy="54" r="9" fill="#e8283a" stroke="#6a0010" stroke-width="2"/>
    <circle cx="44" cy="12" r="11" fill="${grey}" stroke="${dark}" stroke-width="2"/><circle cx="44" cy="12" r="6" fill="${pink}"/>
    <circle cx="72" cy="10" r="11" fill="${grey}" stroke="${dark}" stroke-width="2"/><circle cx="72" cy="10" r="6" fill="${pink}"/>
    <circle cx="60" cy="30" r="17" fill="${grey}" stroke="${dark}" stroke-width="2.5"/>
    <path d="M47 20 L74 13 L70 5 Z" fill="#ffd21c" stroke="#9a6a00" stroke-width="2" stroke-linejoin="round"/>
    <circle cx="62" cy="13" r="1.8" fill="#d8a000"/><circle cx="68" cy="10" r="1.4" fill="#d8a000"/>
    <ellipse cx="74" cy="36" rx="8" ry="6" fill="${grey}" stroke="${dark}" stroke-width="2"/>
    <circle cx="81" cy="34" r="3.2" fill="${pink}" stroke="${dark}" stroke-width="1.2"/>
    <rect x="70" y="41" width="4" height="5" fill="#fff" stroke="${dark}" stroke-width="1"/><rect x="74" y="41" width="4" height="5" fill="#fff" stroke="${dark}" stroke-width="1"/>
    <path d="M76 36 L88 33 M76 38 L88 39" stroke="${dark}" stroke-width="1"/>
    ${f === 3 ? `<ellipse cx="72" cy="45" rx="4" ry="3" fill="#6a0010"/>` : ""}${eyes}${glove}</g>`;
}
for (let f = 0; f < 4; f++) save("spr_mouse_" + f, 92, 84, mouse(f));

function hen(f) {
  const ink = "#5a3a1a", comb = "#e8283a";
  const head = f === 2 ? `translate(6 10) rotate(18 58 26)` : "translate(0 0)";
  const wing = f === 1
    ? `<path d="M30 44 Q20 14 46 22 Q44 38 30 44 Z" fill="#f2f2f2" stroke="${ink}" stroke-width="2"/>`
    : `<ellipse cx="36" cy="52" rx="15" ry="10" fill="#efefef" stroke="${ink}" stroke-width="2"/>`;
  const eye = f === 3
    ? `<path d="M58 20 L64 26 M64 20 L58 26" stroke="#222" stroke-width="2.5" stroke-linecap="round"/>`
    : `<circle cx="61" cy="23" r="4" fill="#fff" stroke="${ink}" stroke-width="1.3"/><circle cx="62.5" cy="23.5" r="2" fill="#111"/>
       <path d="M54 16 L67 20" stroke="#222" stroke-width="3" stroke-linecap="round"/>`;
  const steam = f !== 3 ? `<path d="M48 4 q-4 -4 0 -8 M56 2 q-4 -4 0 -8" stroke="#fff" stroke-width="2.5" fill="none" opacity="0.8"/>` : "";
  return `<path d="M18 44 Q2 30 8 18 Q14 30 22 30 Q14 18 22 10 Q26 26 30 34 Z" fill="#fff" stroke="${ink}" stroke-width="2"/>
    <path d="M34 70 L32 82 M28 82 L36 82 M48 70 L50 82 M46 82 L54 82" stroke="#ff9a1c" stroke-width="3" stroke-linecap="round"/>
    <ellipse cx="42" cy="52" rx="26" ry="22" fill="#fff" stroke="${ink}" stroke-width="2.5"/>
    ${wing}
    <g transform="${head}">
      <path d="M48 12 Q50 2 55 8 Q58 0 62 8 Q67 2 67 13 Z" fill="${comb}" stroke="#7a0010" stroke-width="1.5"/>
      <circle cx="58" cy="26" r="14" fill="#fff" stroke="${ink}" stroke-width="2.5"/>
      <circle cx="56" cy="31" r="5" fill="#ff6a6a" opacity="0.7"/>
      <path d="M70 24 L84 28 L70 33 Z" fill="#ffc21c" stroke="#9a6a00" stroke-width="1.6" stroke-linejoin="round"/>
      <path d="M69 34 Q72 42 67 42 Q64 38 66 34 Z" fill="${comb}" stroke="#7a0010" stroke-width="1.2"/>
      ${eye}${steam}
    </g>
    ${f === 3 ? `<path d="M10 60 l6 -4 M76 56 l6 -6 M20 74 l-4 6" stroke="#fff" stroke-width="3"/>` : ""}`;
}
for (let f = 0; f < 4; f++) save("spr_hen_" + f, 92, 86, hen(f));

save("spr_cheese", 22, 18,
  `<path d="M2 16 L20 16 L20 4 Z" fill="#ffd21c" stroke="#9a6a00" stroke-width="1.8" stroke-linejoin="round"/>
   <path d="M2 16 L20 4 L14 1 Z" fill="#ffe680" stroke="#9a6a00" stroke-width="1.5" stroke-linejoin="round"/>
   <circle cx="14" cy="12" r="2" fill="#d8a000"/><circle cx="17" cy="8" r="1.4" fill="#d8a000"/>`);
save("spr_feather", 14, 26,
  `<path d="M7 25 Q1 14 7 1 Q13 14 7 25 Z" fill="#ffffff" stroke="#8a7a6a" stroke-width="1.3"/>
   <path d="M7 25 L7 4" stroke="#b8a890" stroke-width="1.2"/><path d="M7 10 L3 7 M7 15 L11 12 M7 19 L3 16" stroke="#c8b8a0" stroke-width="1"/>`);
save("spr_egg", 22, 28,
  `<ellipse cx="11" cy="15" rx="9" ry="12" fill="#fff4dc" stroke="#b8945a" stroke-width="1.6"/>
   <circle cx="7" cy="17" r="1.4" fill="#c89a5a"/><circle cx="13" cy="21" r="1.1" fill="#c89a5a"/><circle cx="14" cy="11" r="1.2" fill="#c89a5a"/><circle cx="9" cy="24" r="0.9" fill="#c89a5a"/>
   <ellipse cx="7.5" cy="9" rx="2.2" ry="3.5" fill="#ffffff" opacity="0.9"/>`);

// ---------- Title logo: chunky 3D cartoon letters ----------
function logo3d(text, size, y, w) {
  let layers = "";
  for (let i = 8; i >= 1; i--) {
    layers += `<text x="${w / 2 + i}" y="${y + i}" text-anchor="middle" font-family="Comic Sans MS" font-weight="bold" font-size="${size}" fill="#1a5a0c" stroke="#0c2a06" stroke-width="6" stroke-linejoin="round">${text}</text>`;
  }
  return layers +
    `<text x="${w / 2}" y="${y}" text-anchor="middle" font-family="Comic Sans MS" font-weight="bold" font-size="${size}" fill="url(#lg)" stroke="#0c2a06" stroke-width="6" stroke-linejoin="round" paint-order="stroke"/>`.replace("/>", `>${text}</text>`) +
    `<text x="${w / 2 - 3}" y="${y - 4}" text-anchor="middle" font-family="Comic Sans MS" font-weight="bold" font-size="${size}" fill="none" stroke="#e8ffb0" stroke-width="2" opacity="0.6">${text}</text>`;
}
save("spr_logo", 640, 200, logo3d("SNAKE", 92, 86, 640) + logo3d("HANGMAN", 78, 176, 640),
  `<linearGradient id="lg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#c6ff6a"/><stop offset="0.5" stop-color="#5cd62a"/><stop offset="1" stop-color="#2e9a14"/></linearGradient>`);

// ---------- HUD font strip: one 30 x 38 cell per glyph ----------
const GLYPHS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!?.:x-/',%()+";
fs.writeFileSync(path.join(OUT, "font_hud_glyphs.txt"), GLYPHS);
let strip = "";
[...GLYPHS].forEach((ch, i) => {
  const esc = ch.replace("&", "&amp;").replace("<", "&lt;").replace("'", "&apos;");
  strip += `<text x="${i * 30 + 15}" y="30" text-anchor="middle" font-family="Comic Sans MS" font-weight="bold" font-size="30" fill="url(#hf)" stroke="#101a40" stroke-width="5" stroke-linejoin="round" paint-order="stroke">${esc}</text>`;
});
save("font_hud", GLYPHS.length * 30, 38, strip,
  `<linearGradient id="hf" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="0.55" stop-color="#fff6a8"/><stop offset="1" stop-color="#ffb21c"/></linearGradient>`);

Promise.all(jobs).then(() => console.log("made " + jobs.length + " images in " + OUT));
