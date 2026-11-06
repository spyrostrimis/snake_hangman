image_index = open ? 1 : 0;
if (hint_cooldown > 0) hint_cooldown--;
if (open && obj_game.frame mod 6 == 0) part_particles_create_colour(obj_game.ps, x + random_range(-10, 10), y - 30 + random_range(-14, 14), obj_game.pt_spark, make_colour_rgb(120, 255, 140), 1);
