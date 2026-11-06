# Snakes and Hangmans

Versions of one game, built with [GameMaker](https://gamemaker.io) while learning it: steer a snake into the letters of a hidden word. A right letter reveals every copy of it and makes the snake grow. A wrong letter costs one of six chances. Six misses, a wall or your own tail end the run.

Each folder is a complete GameMaker project. Open its `.yyp` file in GameMaker, or build it from the command line with [GM-CLI](https://www.npmjs.com/package/@gamemaker/gm-cli) (`npx @gamemaker/gm-cli run` inside the folder).

| Folder | Look |
| --- | --- |
| [`snake_hangman/`](snake_hangman/) | v1: neon pixel art, with a pixel font drawn in code. |
| [`snake_hangman2/`](snake_hangman2/) | v2: dressed as the Hall of Fame page of [Hangman: Rescue Mission](https://hangman.spyrostrimis.com), with its moon background, Bruno Ace SC, colours, Artsy and an arcade-style local Hall of Fame. |
| [`snake_hangman4/`](snake_hangman4/) | v4, "Bubble Rounds": a tribute to the bubble arcades of the 80s, and above all to Taito's *Bubble Bobble* (1986). It runs at 320 × 240 shown at 3×, with brick rounds in a new colour each time, letter bubbles, a word column and six chances, lives, treats, a spiky enemy called Fizz, "HURRY UP!", a gap in the walls to wrap through, the scroll between rounds, a chiptune made in code, scanlines and a Best 5 table with initials. All the art, characters, rounds and music are original. |
| [`snake_hangman3/`](snake_hangman3/) | v3: the site's homepage look (warp-speed stars, frosted glass, crew pods), plus four stages with walls, space debris on paths, Han's hint orb, Artsy reviving letter by letter, a particle starfield, a shader on the play field and sound effects made in code. |

## Credits

- v2 and v3 artwork (backgrounds, Artsy, Han Fastolfe and Illucia) comes from [spyrostrimis/hangman](https://github.com/spyrostrimis/hangman).
- v2 and v3 use the [Bruno Ace SC](https://fonts.google.com/specimen/Bruno+Ace+SC) font by Astigmatic, under the [SIL Open Font License 1.1](https://openfontlicense.org).
- v3 uses [Techno Board](https://www.fontspace.com/techno-board-font-f56892) by PutraCetol, free for non-commercial use. Its free version draws digits as the designer's logo, so v3 sets numbers in Bruno Ace SC.
