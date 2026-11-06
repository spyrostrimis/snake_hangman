/// Free what GameMaker does not free by itself: surface, particle systems, paths, sounds.
if (surface_exists(field_surface)) surface_free(field_surface);
part_type_destroy(pt_warp);
part_type_destroy(pt_spark);
part_type_destroy(pt_ring);
part_type_destroy(pt_trail);
part_system_destroy(ps_back);
part_system_destroy(ps_front);
for (var _i = 0; _i < array_length(debris_paths); _i++) path_delete(debris_paths[_i]);
sfx_free(sfx);
