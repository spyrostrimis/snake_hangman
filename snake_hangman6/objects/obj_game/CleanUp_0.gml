/// Free the music stream, the synthesised sounds and the particle system.
stop_music();
sfx_free(sfx);
part_type_destroy(pt_spark);
part_type_destroy(pt_dust);
part_type_destroy(pt_rock);
part_system_destroy(ps);
