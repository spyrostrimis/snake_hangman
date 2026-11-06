/// Creatures only move during play; each child adds its own movement after this.
if (obj_game.state != "play" && obj_game.state != "title" && obj_game.state != "credits") { image_speed = 0; exit; }
image_speed = 0.15;
