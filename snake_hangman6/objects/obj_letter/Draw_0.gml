/// The bubble, a soft glow and the letter inside it.
gpu_set_blendmode(bm_add);
draw_set_colour(make_colour_rgb(80, 160, 255));
draw_set_alpha(0.25 + 0.1 * sin(bob * 2));
draw_circle(x, y, 20, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_self();
hud_text(x, y - 11, ch, 0.55, fa_center);
