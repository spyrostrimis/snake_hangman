mission_clear();
ini_open("embersand.ini");
ini_write_real("settings", "side", global.player_side);
ini_write_real("settings", "difficulty", global.difficulty);
ini_close();
sfx_free(global.sfx);
fx_free();
ds_list_destroy(global.tmp_list);
