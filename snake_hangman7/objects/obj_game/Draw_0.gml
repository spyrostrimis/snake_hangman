/// Selection marks, health bars and the placement outline, then the shroud over everything in the world.
if (global.state != "play" && global.state != "end") exit;
world_overlay_draw();
shroud_draw();
