// When dead tint screen black
if global.blackScreen {
	draw_rectangle_color(0,0,view_wport[0], view_hport[0],0,0,0,1,0)
}

var _x_offset = 10;
var _y_offset = 5;
var _line_height = 15;
with (obj_player) {
	var _line = player_number;
	var _line_y = _y_offset + _line_height * _line;
	draw_set_color(color);
	draw_rectangle(_x_offset, _line_y + 5,_x_offset + 10,_line_y + 15, false);
	draw_set_color(c_white);
	draw_text(_x_offset + 20, _line_y, "HP: " + string(hp));
	draw_text(_x_offset + 100, _line_y, "Arrows: " + string(arrows));
}

var _bottom = display_get_gui_height();
var _line_y = _bottom - 10 - _line_height;
draw_text(_x_offset, _line_y, "Level: " + string(global.currentLevel));
draw_text(_x_offset + 90, _line_y, string(global.keyFound ? "You found the key!" : "You will need a key."));

// Debug overlay (toggle with F3): split-screen checkbox + player-light sliders
if (global.show_voron_debug) {
	var _l = debug_overlay_layout();

	// Panel
	draw_set_alpha(0.75);
	draw_set_color(c_black);
	draw_rectangle(_l.px, _l.py, _l.px + _l.pw, _l.py + _l.ph, false);
	draw_set_alpha(1);
	draw_set_color(c_white);
	draw_rectangle(_l.px, _l.py, _l.px + _l.pw, _l.py + _l.ph, true);

	// Checkbox
	draw_rectangle(_l.bx, _l.by, _l.bx + _l.box, _l.by + _l.box, true);
	if (global.voron_splitscreen_enabled) {
		draw_set_color(c_lime);
		draw_rectangle(_l.bx + 3, _l.by + 3, _l.bx + _l.box - 3, _l.by + _l.box - 3, false);
		draw_set_color(c_white);
	}
	draw_text(_l.bx + _l.box + 8, _l.py + 7, "Enable Voronoi Splitscreen");

	// Range slider (0-10 -> 0-600px)
	var _rv = global.player_light_range_slider;
	draw_text(_l.range_track_x, _l.range_label_y,
		"Light Range: " + string(round(_rv * 60)) + "px");
	debug_overlay_draw_slider(_l.range_track_x, _l.range_track_y, _l.range_track_w,
		_l.track_h, _l.handle_w, _l.handle_h, _rv / 10);

	// Intensity slider (0-10)
	var _iv = global.player_light_intensity_slider;
	draw_text(_l.inten_track_x, _l.inten_label_y,
		"Light Intensity: " + string(round(_iv * 10) / 10));
	debug_overlay_draw_slider(_l.inten_track_x, _l.inten_track_y, _l.inten_track_w,
		_l.track_h, _l.handle_w, _l.handle_h, _iv / 10);

	draw_set_color(c_white);
	draw_set_alpha(1);
}
