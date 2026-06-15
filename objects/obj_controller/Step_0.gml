move_to_center(camera_target, objects_of_type(obj_player));

for (var i = 0; i<20; i++) {
	var val = gamepad_button_check(4, i);
	if (val != 0) {
		show_debug_message("gp press(" + string(i) + "): " + string(gamepad_button_check(4, i)));
	}
}

for (var i = 0; i<20; i++) {
	for (var j =0; j<20; j++) {
		var val = gamepad_axis_value(i, j);
		if (val != 0) {
			show_debug_message("gp axis(" + string(i) + "," + string(j) + "): " + string(val));
		}
	}
}

global.blackScreen = false

// Debug overlay: F3 toggles it; clicking the panel toggles Voronoi split-screen
if (keyboard_check_pressed(vk_f3)) {
	global.show_voron_debug = !global.show_voron_debug;
}
if (global.show_voron_debug && mouse_check_button_pressed(mb_left)) {
	var _l = debug_overlay_layout();
	var _mx = device_mouse_x_to_gui(0);
	var _my = device_mouse_y_to_gui(0);
	if (point_in_rectangle(_mx, _my, _l.px, _l.py, _l.px + _l.pw, _l.py + _l.ph)) {
		voron_set_splitscreen(!global.voron_splitscreen_enabled);
	}
}

check_game_over();
