/// A piece of space debris. obj_game gives it a path (path_start) and draws it inside the field.
visible = false;
spin = random_range(1.5, 3.5) * choose(-1, 1);
image_angle = random(360);
debris_radius = 12;

// An irregular rock: eight corners at slightly different distances.
corners = [];
for (var _i = 0; _i < 8; _i++) array_push(corners, random_range(0.72, 1.0));
