enum VEC_INPUT_DEVICE {
	GP_LEFT_STICK,
	GP_RIGHT_STICK,
	KEYS,
	MOUSE,
	FUNCTIONS,
}

enum DEVICE {
	GAMEPAD_ONE = 0,
	GAMEPAD_TWO = 1,
	GAMEPAD_THREE = 2,
	GAMEPAD_FOUR = 3,
	KEYBOARD = -1,
}

enum BTN_TYPE {
	KEYBOARD,
	MOUSE,
	GAMEPAD,
}

function MouseButton(_mb) constructor {
	type = BTN_TYPE.MOUSE;
	button = _mb;
}

// A gamepad button, optionally inverted. Used for gp_shoulderlb/gp_shoulderrb (LT/RT), whose
// "digital" reading is inverted on some pads (idle reads as down, pulling the trigger reads
// as not-down).
function GamepadButton(_button, _inverted = false, _is_axis = false, _axis_threshold = 0.25) constructor {
	type = BTN_TYPE.GAMEPAD;
	button = _button;
	inverted = _inverted;
	is_axis = _is_axis;
	axis_threshold = _axis_threshold;
}

function snes_gp_default(_gp_id) {
	gp_id = _gp_id;
	var _up = function() {
		return !gamepad_button_check(gp_id, 12)
			&& !gamepad_button_check(gp_id, 13);
	}

	var _down = function() {
		return gamepad_button_check(gp_id, 13);
	}

	var _left = function() {
		return !gamepad_button_check(gp_id, 14)
			&& !gamepad_button_check(gp_id, 15);
	}
	var _right = function() {
		return gamepad_button_check(gp_id, 15);
	}

	return new PlayerKeyBinding(
		_gp_id,
		new VectorInput(
			VEC_INPUT_DEVICE.FUNCTIONS,
			_up,
			_down,
			_left,
			_right
		),
		new VectorInput(VEC_INPUT_DEVICE.KEYS, 3, 0, 2, 1),
		gp_shoulderr,
		gp_shoulderl,
		gp_face1
	);
}

// 8BitDo pads (SN30 Pro, Pro 2, Ultimate, ...) present as a standard XInput controller on
// Windows, so they expose analog sticks and the usual face/shoulder buttons. Unlike the SNES
// pad (digital D-pad + face buttons), this binding uses the left stick to move and the right
// stick to aim. Shoot is the right trigger (RT), interact is the left bumper (LB), and pickup
// is the A button.
function eightbitdo_gp_default(_gp_id) {
	var _aim = new VectorInput(VEC_INPUT_DEVICE.GP_RIGHT_STICK);
	var _shoot;
	if (os_type == 24) { // 24 = os_gxgames
		// gx.games axis layout: a2=right stick X, a4=RT, a5=right stick Y (0-1, 0.5=neutral)
		_aim.axis_h = 2;
		_aim.axis_v = 5;
		_aim.gx_normalize_v = true; // a5 (right stick Y) is 0-1 centred at 0.5; a2 (X) is standard
		_shoot = new GamepadButton(4, false, true); // RT is axis 4, read as button
	} else {
		_shoot = new GamepadButton(gp_shoulderrb);
	}
	var _move = new VectorInput(VEC_INPUT_DEVICE.GP_LEFT_STICK);
	var _b = new PlayerKeyBinding(
		_gp_id,
		_move,
		_aim,
		_shoot,
		gp_face1,                                  // A = interact (enter door)
		(os_type == 24) ? gp_shoulderl : gp_face4 // Y = pickup (gp_shoulderl maps to Y on gx.games HID)
	);
	_b.auto_gamepad = true;	// track the first connected pad live
	return _b;
}

// Returns the slot of the first connected gamepad, or 0 if none is connected. Handy for
// assigning a binding without hard-coding which slot the pad happened to land on.
// Note: gamepad_get_device_count() can under-report the number of slots to scan (it returned
// a count that excluded a pad sitting on slot 4), so scan a fixed range of slots directly via
// gamepad_is_connected() instead of bounding the loop by the device count.
function gp_first_connected() {
	for (var i = 0; i < 12; i++) {
		if (gamepad_is_connected(i)) return i;
	}
	return 0;
}

function keyboard_default() {
	return new PlayerKeyBinding(
		DEVICE.KEYBOARD,
		new VectorInput(
			VEC_INPUT_DEVICE.KEYS,
			ord("W"),
			ord("S"),
			ord("A"),
			ord("D")
		),
		new VectorInput(VEC_INPUT_DEVICE.MOUSE),
		new MouseButton(mb_left),
		ord("E"),
		ord("R")
	);
}

function keyboard_ply2_default() {
	return new PlayerKeyBinding(
		DEVICE.KEYBOARD,
		new VectorInput(
			VEC_INPUT_DEVICE.KEYS,
			ord("T"),
			ord("G"),
			ord("F"),
			ord("H")
		),
		new VectorInput(VEC_INPUT_DEVICE.MOUSE),
		new MouseButton(mb_left),
		ord("E"),
		ord("Y")
	);
}

/// @struct VectorInput
/// @param {VEC_INPUT_DEVICE} _vec_input_device - Joystick input type (GP_LEFT_STICK, GP_RIGHT_STICK, KEYS)
/// @param {string} [_up] - Key for up movement (optional)
/// @param {string} [_down] - Key for down movement (optional)
/// @param {string} [_left] - Key for left movement (optional)
/// @param {string} [_right] - Key for right movement (optional)
function VectorInput(_vec_input_device, _up = undefined, _down = undefined, _left = undefined, _right = undefined) constructor {
	vec_input_device = _vec_input_device;
	up = _up;
	down = _down;
	left = _left;
	right = _right;
}

/// @function PlayerKeyBinding
/// @param {string} _device - "keyboard" or "gamepad"
/// @param {struct.VectorInput} _move_vec_input
/// @param {struct.VectorInput} _aim_vec_input
/// @param _shoot_btn
/// @param _interact_btn
/// @param _pickup_btn
function PlayerKeyBinding(
    _device,
    _move_vec_input,
    _aim_vec_input,
    _shoot_btn,
	_interact_btn,
	_pickup_btn
) constructor {
    device = _device;
    move_vec_input = _move_vec_input;
    shoot_btn = _shoot_btn;
	interact_btn = _interact_btn;
	pickup_btn = _pickup_btn;
    aim_vec_input = _aim_vec_input;

	// When true, this gamepad binding re-resolves its slot to the first connected pad every
	// time it's read, so it keeps working if the controller enumerates late or lands on a
	// different slot than when the binding was created. Set by eightbitdo_gp_default.
	auto_gamepad = false;
	_refresh = function() {
		if (auto_gamepad) device = gp_first_connected();
	}

	// gamepad_button_check_pressed() doesn't edge-detect cleanly for the trigger-derived
	// "buttons" (gp_shoulderlb/gp_shoulderrb on LT/RT) - it reports down on every frame the
	// trigger is held, not just the frame it crosses the threshold. Track each gamepad
	// button's previous state ourselves so pressed() is a true press-edge for those too.
	_gp_prev_down = {};

    pressed = function(_key) {
		_refresh();
		if (_key == undefined) {
			return false;
		}
		if (variable_struct_exists(_key, "type") && _key.type == BTN_TYPE.MOUSE) {
			return mouse_check_button_pressed(_key.button);
		}
		if (variable_struct_exists(_key, "type") && _key.type == BTN_TYPE.GAMEPAD) {
			if (variable_struct_exists(_key, "is_axis") && _key.is_axis) {
				// RT (or any trigger) exposed as an axis on this platform — edge-detect via threshold
				var _name = "ax" + string(_key.button);
				var _down = gamepad_axis_value(self.device, _key.button) > _key.axis_threshold;
				var _was_down = variable_struct_exists(_gp_prev_down, _name) ? _gp_prev_down[$ _name] : false;
				_gp_prev_down[$ _name] = _down;
				return _down && !_was_down;
			}
			if (_key.inverted) {
				// Idle = button-down on this pad; trigger-pulled = button-up.
				// gamepad_button_check_released fires once on the DOWN→UP transition,
				// which is exactly when the trigger is physically pressed.
				return gamepad_button_check_released(self.device, _key.button);
			}
			var _name = string(_key.button);
			var _down = gamepad_button_check(self.device, _key.button);
			var _was_down = variable_struct_exists(_gp_prev_down, _name) ? _gp_prev_down[$ _name] : false;
			_gp_prev_down[$ _name] = _down;
			return _down && !_was_down;
		}
        if (self.device == DEVICE.KEYBOARD) {
            return keyboard_check_pressed(_key);
        } else {
			var _name = string(_key);
			var _down = gamepad_button_check(self.device, _key);
			var _was_down = variable_struct_exists(_gp_prev_down, _name) ? _gp_prev_down[$ _name] : false;
			_gp_prev_down[$ _name] = _down;
			return _down && !_was_down;
        }
    }
		
	released = function(_key) {
		if (_key == undefined) {
			return false;
		}
        if (self.device == DEVICE.KEYBOARD) {
            return keyboard_check_released(_key);
        } else {
            return gamepad_button_check_released(self.device, _key);
        }
    }
		
	is_down = function(_key, _vec_input_device) {
		_refresh();
		if (_key == undefined) {
			return false;
		}
		if (_vec_input_device == VEC_INPUT_DEVICE.FUNCTIONS) {
			return _key();
		}
        if (self.device == DEVICE.KEYBOARD) {
            return keyboard_check(_key);
        } else {
            return gamepad_button_check(self.device, _key);
        }
    }
		
	shoot = function() {
		return self.pressed(self.shoot_btn);
	}
	
	interact = function() {
		return self.pressed(self.interact_btn);
	}

	pickup = function() {
		return self.pressed(self.pickup_btn);
	}

	// Stick drift below this magnitude is ignored (prevents auto-walk / auto-aim)
	stick_deadzone = 0.25;

	function get_unit_vec(_vec_input) {
		_refresh();
		var v = new Vec2(0,0);
		if (_vec_input.vec_input_device == VEC_INPUT_DEVICE.GP_LEFT_STICK) {
			// Left stick (with deadzone) OR the d-pad can drive movement
			v.x = gamepad_axis_value(device, gp_axislh);
			v.y = gamepad_axis_value(device, gp_axislv);
			if (abs(v.x) < stick_deadzone) v.x = 0;
			if (abs(v.y) < stick_deadzone) v.y = 0;
			v.x += gamepad_button_check(device, gp_padr) - gamepad_button_check(device, gp_padl);
			v.y += gamepad_button_check(device, gp_padd) - gamepad_button_check(device, gp_padu);
			// Clamp to unit length so stick + d-pad together can't move faster than max speed
			var _len = point_distance(0, 0, v.x, v.y);
			if (_len > 1) { v.x /= _len; v.y /= _len; }
		} else if (_vec_input.vec_input_device == VEC_INPUT_DEVICE.GP_RIGHT_STICK) {
			// Use axis overrides if the binding supplied them (e.g. HTML5 where right stick is
			// on axes 4/5 instead of GML's default gp_axisrh=2 / gp_axisrv=3).
			var _html5 = (os_type == 24); // 24 = os_gxgames
			var _rh = variable_struct_exists(_vec_input, "axis_h") ? _vec_input.axis_h : (_html5 ? 4 : gp_axisrh);
			var _rv = variable_struct_exists(_vec_input, "axis_v") ? _vec_input.axis_v : (_html5 ? 5 : gp_axisrv);
			v.x = gamepad_axis_value(device, _rh);
			v.y = gamepad_axis_value(device, _rv);
			// a5 (right stick Y on gx.games) is 0-1 centred at 0.5; remap to standard -1 to 1
			if (variable_struct_exists(_vec_input, "gx_normalize_v") && _vec_input.gx_normalize_v) {
				v.y = (v.y - 0.5) * 2;
			}
			if (abs(v.x) < stick_deadzone) v.x = 0;
			if (abs(v.y) < stick_deadzone) v.y = 0;
		} else {
			var _right = is_down(_vec_input.right,_vec_input.vec_input_device);
			var _left = is_down(_vec_input.left, _vec_input.vec_input_device);
			var _up = is_down(_vec_input.up,_vec_input.vec_input_device);
			var _down = is_down(_vec_input.down,_vec_input.vec_input_device);
			if (_right == 0 && _left == 0 && _up == 0 && _down == 0) {
				return v;
			}
			var xx = _right - _left;
			var yy = _down - _up;

			var _dir = point_direction(0,0,xx,yy);
			v.x = lengthdir_x(1, _dir);
			v.y = lengthdir_y(1, _dir);
		}

		return v;
	}
	
	move_vec = function() {
		return get_unit_vec(move_vec_input);
	}
	
	aim_vec = function() {
		if (aim_vec_input.vec_input_device == VEC_INPUT_DEVICE.MOUSE) {
			return new Vec2(mouse_x, mouse_y);
		}
		return get_unit_vec(aim_vec_input);
	}

	// Whether aim_vec() returns an absolute mouse target (true) or a relative
	// direction (false). Lets obj_player decide how to place the aim reticle.
	is_mouse_aim = function() {
		return aim_vec_input.vec_input_device == VEC_INPUT_DEVICE.MOUSE;
	}

}

/// A binding that accepts keyboard/mouse AND gamepad at the same time. Movement and the
/// shoot/interact buttons are OR'd across both; aiming follows whichever device was used
/// most recently (move the mouse -> mouse aim, deflect the right stick -> stick aim).
/// @param {struct.PlayerKeyBinding} _kb - keyboard/mouse binding
/// @param {struct.PlayerKeyBinding} _gp - gamepad binding
function HybridKeyBinding(_kb, _gp) constructor {
	kb = _kb;
	gp = _gp;
	aim_is_mouse = true;	// current aim mode
	prev_mx = window_mouse_get_x();
	prev_my = window_mouse_get_y();

	move_vec = function() {
		var _a = kb.move_vec();
		var _b = gp.move_vec();
		var v = new Vec2(_a.x + _b.x, _a.y + _b.y);
		var _len = point_distance(0, 0, v.x, v.y);
		if (_len > 1) { v.x /= _len; v.y /= _len; }
		return v;
	}

	shoot    = function() { return kb.shoot()    || gp.shoot();    }
	interact = function() { return kb.interact() || gp.interact(); }
	pickup   = function() { return kb.pickup()   || gp.pickup();   }

	is_mouse_aim = function() { return aim_is_mouse; }

	aim_vec = function() {
		// Pick the active aim device this frame. The right stick wins while deflected;
		// otherwise physically moving the mouse (or clicking) switches back to mouse aim.
		// Use window-space mouse coords so a moving camera doesn't look like mouse movement.
		var _stick = gp.aim_vec();
		var _wmx = window_mouse_get_x();
		var _wmy = window_mouse_get_y();
		var _mouse_moved = (_wmx != prev_mx) || (_wmy != prev_my);
		prev_mx = _wmx;
		prev_my = _wmy;

		if (_stick.x != 0 || _stick.y != 0) {
			aim_is_mouse = false;
		} else if (_mouse_moved || mouse_check_button_pressed(mb_left)) {
			aim_is_mouse = true;
		}

		return aim_is_mouse ? kb.aim_vec() : _stick;
	}
}

/// Player-one default: keyboard/mouse and gamepad together.
function keyboard_and_gamepad_default() {
	return new HybridKeyBinding(keyboard_default(), eightbitdo_gp_default(gp_first_connected()));
}












