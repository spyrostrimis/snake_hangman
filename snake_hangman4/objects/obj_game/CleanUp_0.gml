/// Free the surfaces and the synthesised sounds.
if (surface_exists(surf_field)) surface_free(surf_field);
if (surface_exists(surf_old)) surface_free(surf_old);
music_stop();
sfx_free(sfx);
