if(travelTime > 0) {
	_entry_dir = direction;	// always capture before decrementing so spawn-frame is correct
	travelTime--;
}

if(fallTime > 0) {
	speed = 0.9*speed;
	image_angle += turnDirection;
	fallTime--;
}

if (travelTime <= 0 && fallTime <= 0) {
	speed = 0;
}

if (position_meeting(x, y, obj_wall)) {
	if (_exit_dir < 0) {
		// Try opposite of penetration direction, but only if exit is within half a tile.
		// Use position_meeting (point check) rather than place_meeting (rotated mask) so that
		// an upward-pointing arrow doesn't falsely appear to still overlap the wall.
		var _try_dir = _entry_dir + 180;
		var _tx = x, _ty = y, _d = 0;
		while (_d < 16 && position_meeting(_tx, _ty, obj_wall)) {
			_tx += lengthdir_x(1, _try_dir);
			_ty += lengthdir_y(1, _try_dir);
			_d++;
		}
		if (!position_meeting(_tx, _ty, obj_wall)) {
			_exit_dir = _try_dir;
		} else {
			// Fallback: shortest exit in any of 8 directions within half a tile, onto floor
			var _best_dist = 999;
			for (var _di = 0; _di < 8; _di++) {
				var _ang = _di * 45;
				_tx = x; _ty = y; _d = 0;
				while (_d < 16 && position_meeting(_tx, _ty, obj_wall)) {
					_tx += lengthdir_x(1, _ang);
					_ty += lengthdir_y(1, _ang);
					_d++;
				}
				if (!position_meeting(_tx, _ty, obj_wall) && position_meeting(_tx, _ty, obj_floor) && _d < _best_dist) {
					_best_dist = _d;
					_exit_dir  = _ang;
				}
			}
			if (_exit_dir < 0) { instance_destroy(); }
		}
	}
	if (_exit_dir >= 0) {
		x += lengthdir_x(4, _exit_dir);
		y += lengthdir_y(4, _exit_dir);
	}
} else {
	_exit_dir = -1;
}

with (obj_enemy_parent) {
	if(other.travelTime > 0) {
		if(hitEnemy(self)) {
			audio_play_sound(snd_arrow_hit_hall,0,0,getGain(other, obj_player, 200) * 0.5)
			with(other) {
				fallToFloor();
			}
			hp -= 20;
			onTakeDamage();
			flash(self);
		}
	}
}