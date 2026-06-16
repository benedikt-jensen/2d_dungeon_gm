event_inherited();

color = #b1e064;

// Use the 8BitDo (analog stick + d-pad) binding on whichever pad is connected.
// For a SNES pad, swap this back to snes_gp_default(<slot>) - that binding has the
// special arrow-pad direction decode the SNES controller needs.
key_binding = eightbitdo_gp_default(gp_first_connected());