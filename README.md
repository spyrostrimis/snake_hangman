# Snakes and Hangmans

Versions of one game, built with [GameMaker](https://gamemaker.io) while learning it: steer a snake into the letters of a hidden word. A right letter reveals every copy of it and makes the snake grow. A wrong letter costs one of six chances. Six misses, a wall or your own tail end the run.

Each folder is a complete GameMaker project. Open its `.yyp` file in GameMaker, or build it from the command line with [GM-CLI](https://www.npmjs.com/package/@gamemaker/gm-cli) (`npx @gamemaker/gm-cli run` inside the folder).

| Folder | Look |
| --- | --- |
| [`snake_hangman/`](snake_hangman/) | v1: neon pixel art, with a pixel font drawn in code. |
| [`snake_hangman2/`](snake_hangman2/) | v2: dressed as the Hall of Fame page of [Hangman: Rescue Mission](https://hangman.spyrostrimis.com), with its moon background, Bruno Ace SC, colours, Artsy and an arcade-style local Hall of Fame. |
| [`snake_hangman4/`](snake_hangman4/) | v4, "Bubble Rounds": a tribute to the bubble arcades of the 80s, and above all to Taito's *Bubble Bobble* (1986). It runs at 320 × 240 shown at 3×, with brick rounds in a new colour each time, letter bubbles, a word column and six chances, lives, treats, a spiky enemy called Fizz, "HURRY UP!", a gap in the walls to wrap through, the scroll between rounds, a chiptune made in code, scanlines and a Best 5 table with initials. All the art, characters, rounds and music are original. |
| [`snake_hangman5/`](snake_hangman5/) | v5, "Jungle Jam": a side-scrolling platformer and a tribute to the 90s PC platformers, *Jazz Jackrabbit 2* above all. The snake runs, jumps, glides on a spinning tail, knocks out creatures and pulls in items with its tongue, and curls into a ball to smash cracked blocks. Each level hides the letters of a secret word; wrong letters are misses, and the exit door only opens when the word is complete. It is built with real GameMaker structures: a runtime tilemap and tileset, parallax background layers, an asset layer of decorations, a camera, parent and child objects, a bitmap font made from a sprite, particle systems and streamed Ogg music. All characters, levels and art are original. |
| [`snake_hangman3/`](snake_hangman3/) | v3: the site's homepage look (warp-speed stars, frosted glass, crew pods), plus four stages with walls, space debris on paths, Han's hint orb, Artsy reviving letter by letter, a particle starfield, a shader on the play field and sound effects made in code. |

## Credits

- v2 and v3 artwork (backgrounds, Artsy, Han Fastolfe and Illucia) comes from [spyrostrimis/hangman](https://github.com/spyrostrimis/hangman).
- v2 and v3 use the [Bruno Ace SC](https://fonts.google.com/specimen/Bruno+Ace+SC) font by Astigmatic, under the [SIL Open Font License 1.1](https://openfontlicense.org).
- v5 art is drawn in code (`snake_hangman5/art_src/make_art.js`, SVG rendered with sharp). Its title and screen text use fonts already on Windows (Comic Sans MS); nothing is bundled.
- v5 music: the [*Jazz Jackrabbit 2 – 20th Anniversary Tribute Album*](https://jj20.bandcamp.com/album/jazz-jackrabbit-2-20th-anniversary-tribute-album) by the JJ20 Team (Megahit, Zyrit, BPStudio, Gridscape, Bitrotator, SIDNIFY, Vincenzo and Ziona), licensed [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/). It covers Alexander Brandon's music, and *Jazz Jackrabbit 2* belongs to Epic Games. The tracks are **not in this repository**. To hear them, download the album (free), convert each track to Ogg Vorbis unchanged, and save them in `snake_hangman5/` as `music_01.ogg` … `music_09.ogg`, numbered by track. Without them the game plays silently, apart from its own sound effects. This is an unofficial fan tribute, not endorsed by Epic Games.
- v3 uses [Techno Board](https://www.fontspace.com/techno-board-font-f56892) by PutraCetol, free for non-commercial use. Its free version draws digits as the designer's logo, so v3 sets numbers in Bruno Ace SC.
