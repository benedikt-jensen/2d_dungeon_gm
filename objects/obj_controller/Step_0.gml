move_to_center(camera_target, objects_of_type(obj_player));

if (instance_exists(obj_player)) {
    var _cam   = view_camera[0];
    var _vw    = camera_get_view_width(_cam);
    var _vh    = camera_get_view_height(_cam);
    var _new_x = lerp(camera_get_view_x(_cam), obj_player.x - _vw * 0.5, 0.1);
    var _new_y = lerp(camera_get_view_y(_cam), obj_player.y - _vh * 0.5, 0.1);
    camera_set_view_pos(_cam,
        clamp(_new_x, 0, room_width  - _vw),
        clamp(_new_y, 0, room_height - _vh));
}

// Gamepad input inspector (only while the F3 debug overlay is on). Logs which slot/button
// index fires on press and which axes are deflected, so an unknown pad's mapping can be read.
if (global.show_voron_debug) {
	for (var _gp = 0; _gp < 12; _gp++) {
		if (!gamepad_is_connected(_gp)) continue;
		for (var _b = 0; _b < 32; _b++) {
			if (gamepad_button_check_pressed(_gp, _b)) {
				show_debug_message("gp " + string(_gp) + " button pressed: " + string(_b));
			}
		}
		for (var _a = 0; _a < 8; _a++) {
			var _v = gamepad_axis_value(_gp, _a);
			if (abs(_v) > 0.5) {
				show_debug_message("gp " + string(_gp) + " axis " + string(_a) + ": " + string(_v));
			}
		}
	}
}

global.blackScreen = false

// Debug overlay: F3 toggles it; the checkbox toggles split-screen, the sliders tune the lights
if (keyboard_check_pressed(vk_f3)) {
	global.show_voron_debug = !global.show_voron_debug;
}
if (global.show_voron_debug) {
	var _l = debug_overlay_layout();
	var _mx = device_mouse_x_to_gui(0);
	var _my = device_mouse_y_to_gui(0);

	if (mouse_check_button_pressed(mb_left)) {
		// Checkbox row toggles split-screen
		if (point_in_rectangle(_mx, _my, _l.px, _l.py, _l.px + _l.pw, _l.py + _l.row1_h)) {
			voron_set_splitscreen(!global.voron_splitscreen_enabled);
		}
		// Start dragging whichever slider was grabbed (generous vertical hit area)
		else if (point_in_rectangle(_mx, _my, _l.range_track_x - 6, _l.range_track_y - 8,
				_l.range_track_x + _l.range_track_w + 6, _l.range_track_y + 8)) {
			global.debug_drag = "range";
		}
		else if (point_in_rectangle(_mx, _my, _l.inten_track_x - 6, _l.inten_track_y - 8,
				_l.inten_track_x + _l.inten_track_w + 6, _l.inten_track_y + 8)) {
			global.debug_drag = "intensity";
		}
	}

	// While the button is held, the active slider follows the mouse (0-10)
	if (mouse_check_button(mb_left)) {
		if (global.debug_drag == "range") {
			global.player_light_range_slider = clamp((_mx - _l.range_track_x) / _l.range_track_w, 0, 1) * 10;
		}
		else if (global.debug_drag == "intensity") {
			global.player_light_intensity_slider = clamp((_mx - _l.inten_track_x) / _l.inten_track_w, 0, 1) * 10;
		}
	}
	else {
		global.debug_drag = "";
	}
}
else {
	global.debug_drag = "";
}

// Apply the player-light settings every frame (so they survive level regeneration, which
// recreates the lights at their object defaults)
with (obj_light_player) {
	light[| eLight.Range]     = global.player_light_range_slider * 60;
	light[| eLight.Intensity] = global.player_light_intensity_slider;
}

check_game_over();
