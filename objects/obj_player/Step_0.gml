var _move_unit = key_binding.move_vec()
var _move_v = _move_unit.mult(moveSpeed);

var _aim_unit = key_binding.aim_vec()
var _aim_v = _aim_unit.mult(aim_speed);

target.x += _aim_v.x;
target.y += _aim_v.y;

if (key_binding.is_mouse_aim()) {
	target.x = screen_mouse_to_room_x();
	target.y = screen_mouse_to_room_y();
} else {
	var _target_dist = point_distance(x,y+arrow_rel_y,target.x,target.y);
	var _target_max_dist = 30;
	var _target_correction_length = max(_target_dist - _target_max_dist, 0);
	var _target_correction_dir = point_direction(target.x,target.y,x,y+arrow_rel_y);
	target.x += lengthdir_x(_target_correction_length,_target_correction_dir);
	target.y += lengthdir_y(_target_correction_length,_target_correction_dir);
}

if key_binding.shoot() {
	flash = 1;

	if(arrows != 0) {
		audio_play_sound(snd_arrow_shoot,0,0)
		arrows--
		var _arrow = instance_create_layer(x, y+arrow_rel_y, layer_get_id("Arrows"), obj_arrow);
		var _dir = point_direction(x, y-10, target.x, target.y)
		_arrow.direction = _dir;
		_arrow.image_angle = _dir;
		_arrow.speed = 8 * global.speedMultiplier;
		_arrow.travelTime = round(30 / global.speedMultiplier);
	}
}

if _move_unit.x != 0 || _move_unit.y != 0 {
	if !is_walking {
		audio_play_sound(snd_footsteps_hall,0,1, 0.6 * global.masterVolume)
		is_walking = true
	}
} else {
	if is_walking {
		audio_stop_sound(snd_footsteps_hall)
		is_walking = false
	}
}

if(_move_v.mag()) {
	if(!place_meeting(x+_move_v.x, y, obj_wall)) {
		x += _move_v.x;
		target.x += _move_v.x;
	}
	if(!place_meeting(x,y+_move_v.y, obj_wall)) {
		y += _move_v.y;
		target.y += _move_v.y;
	}
}

with(obj_arrow) {
	if(travelTime <= 0) {
		if(point_distance(other.x, other.y, x+lengthdir_x(8,image_angle), y+lengthdir_y(8,image_angle)) < 12) {
			audio_play_sound(snd_pick_up_arrow_2,0,0, global.masterVolume);
			instance_destroy(self);
			other.arrows++;
		}
	}
}

// Pick up nearby resting arrows on demand - lets the player grab arrows stuck inside/behind
// a wall that the 12px walk-over pickup above can't reach.
if key_binding.pickup() {
	with(obj_arrow) {
		if(travelTime <= 0) {
			if(point_distance(other.x, other.y, x, y) < 48) {
				audio_play_sound(snd_pick_up_arrow_2,0,0, global.masterVolume);
				instance_destroy(self);
				other.arrows++;
			}
		}
	}
}

// Make helmet follow player
if (variable_instance_exists(id, "helmet")) {
	helmet.x = x
	helmet.y = y + 1
}