global.Drawable = function(_sprite, _x, _y) constructor {
	sprite = _sprite;
	x = _x;
	y = _y;
}

global.ds_flash = ds_map_create()
global.ds_depthsort = ds_grid_create(2,1)
global.ds_tooltip = ds_queue_create();
global.blackScreen = false
global.speedMultiplier = 1.0;

function check_game_over() {
	var _all_players_dead = true;
	with (obj_player) {
		if(hp > 0) {
			_all_players_dead = false;
		}
	}
	if (_all_players_dead) {
		global.gameOver = true;
		restart();
	}
}

function draw_tooltip(sprite, x, y) {
	ds_queue_enqueue(global.ds_tooltip, new global.Drawable(sprite, x, y));
}

function wander() {
	if(!place_meeting(x+wanderXSpeed, y, obj_wall)) x += wanderXSpeed;
	if(!place_meeting(x, y+wanderYSpeed, obj_wall)) y += wanderYSpeed;
	wanderXSpeed = clamp(wanderXSpeed + random(0.1) - 0.05, -0.3, 0.3) * global.speedMultiplier;
	wanderYSpeed = clamp(wanderYSpeed + random(0.1) - 0.05, -0.3, 0.3) * global.speedMultiplier;
}

function fallToFloor() {
	if(travelTime > 0) {
		travelTime = 0;
		fallTime = 20;
		turnDirection = (random(1) < 0.5 ? -1 : 1) * random(4);
		speed = 3;
		if(other.object_index==obj_wall) {
			direction = point_direction(other.x+16,other.y+16,x,y);
		} else {
			direction = direction+180;
		}
	}
}

function hitEnemy(enemy){
	if (enemy.object_index == obj_bat) {
		return collision_circle(
			enemy.x, enemy.y - sprite_height / 2,
			enemy.radius,
			other, true, false)
	}
	return collision_rectangle(
		enemy.x - enemy.sprite_xoffset, enemy.y - enemy.sprite_height,
		enemy.x + enemy.sprite_xoffset, enemy.y + enemy.sprite_height - enemy.sprite_yoffset,
		other, true, false)
}
function flash(obj) {
	flashColor(obj, c_white)
}
function flashColor(obj, color) {
	global.ds_flash[? obj] = 1
	obj.flashColor = color
}
function depthsort(parentObj) {
	var dgrid = global.ds_depthsort
	var inst_num = instance_number(par_depthsort)
	ds_grid_resize(dgrid, 2, inst_num)
	
	var i = 0; with(parentObj) {
		dgrid[# 0, i] = id
		dgrid[# 1, i] = y
		i++
	}
	
	ds_grid_sort(dgrid, 1, true)
}
function drawSorted(parentObj) {
	//sort instances by y-coordinate
	depthsort(parentObj)
	var dgrid = global.ds_depthsort
	var inst
	var _objs_with_shadow = [obj_player, obj_enemy, obj_enemy_ram, obj_spider, 
		obj_spider_small, obj_bat, obj_barrel, obj_health_potion];

	var i = 0; repeat(ds_grid_height(dgrid)) {
		//pull out id
		inst = dgrid[# 0, i]
		//draw each instance
		with(inst) {
			var _color = variable_instance_exists(inst, "color") ? inst.color : c_white;
			if (array_contains(_objs_with_shadow, object_index)) {
				var _shadow_scale = 2.5 * radius / sprite_get_width(spr_shadow);
				draw_sprite_ext(spr_shadow,0,x,y,_shadow_scale,_shadow_scale,0,c_white,1);
			}
			draw_sprite_ext(inst.sprite_index, inst.image_index, 
				inst.x, inst.y, 
				inst.image_xscale, inst.image_yscale, 
				inst.image_angle, 
				_color, inst.image_alpha);
			drawFlashEffect();
			if (variable_instance_exists(id, "drawables")) {
				for (j=0; j<ds_list_size(drawables); j++) {
					drawable = ds_list_find_value(drawables, j)
					draw_sprite_ext(drawable.sprite, 0, x + drawable.x, y + drawable.y, 1, 1, 0, c_white, 1)
				}
			}
		}
		i++
	}
}
function drawFlashEffect() {
	//draw flash effect when hit
	if(global.ds_flash[? self] != undefined) {
		gpu_set_fog(true, id.flashColor, 0, 1)
		if(global.ds_flash[? self] > 0) {
			draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, c_white, global.ds_flash[? self])
			global.ds_flash[? self] -= 0.1;
		}
		gpu_set_fog(false, c_white, 0, 0)
	}
}
function getGain(source, listener, max_distance) {
	_dist = point_distance(source.x,source.y, listener.x, listener.y)
	return clamp((max_distance - _dist) / max_distance,0,1) * global.masterVolume;
}
function audio_play_random(soundids, priority, loops, gain = 1) {
	_index = irandom_range(0,array_length(soundids) - 1);
	audio_play_sound(soundids[_index], priority, loops, gain)
}

function objects_of_type(_obj_index) {
	var _res = [];
	with (_obj_index) {
		array_push(_res, id);
	}
	return _res;
}

/// @desc Room-space position of the OS cursor. The game renders view 0 to a surface and scales
///       it to the whole display (see obj_viewcontrol Post Draw), so the built-in mouse_x/y
///       (which assume the view port) don't line up with what's on screen - the in-game cursor
///       ends up moving faster than the OS cursor. These map the window cursor through the
///       same display/view scale the renderer uses, so the two match.
function screen_mouse_to_room_x() {
	var _cam = view_camera[0];
	return camera_get_view_x(_cam) + window_mouse_get_x() * (camera_get_view_width(_cam) / display_get_width());
}
function screen_mouse_to_room_y() {
	var _cam = view_camera[0];
	return camera_get_view_y(_cam) + window_mouse_get_y() * (camera_get_view_height(_cam) / display_get_height());
}

/// @desc Layout (in GUI space) of the F3 debug overlay panel in the top-right corner.
///       Shared by the input handling (obj_controller Step) and the draw (obj_controller Draw
///       GUI) so the clickable/draggable areas always match what's drawn.
/// @returns Struct with the panel, checkbox and the two slider tracks
function debug_overlay_layout() {
	var _gw = display_get_gui_width();
	var _pad = 10;
	var _pw = 250;
	var _ph = 118;
	var _px = _gw - _pw - _pad;
	var _py = _pad;
	var _box = 16;
	var _track_x = _px + 12;
	var _track_w = _pw - 24;
	return {
		px: _px, py: _py, pw: _pw, ph: _ph,
		// Checkbox row (top)
		row1_h: 24,
		bx: _px + 8, by: _py + 8, box: _box,
		// Range slider
		range_label_y: _py + 32,
		range_track_x: _track_x, range_track_y: _py + 52, range_track_w: _track_w,
		// Intensity slider
		inten_label_y: _py + 74,
		inten_track_x: _track_x, inten_track_y: _py + 94, inten_track_w: _track_w,
		// Shared slider visuals
		track_h: 4, handle_w: 8, handle_h: 14
	};
}

/// @desc Draw a horizontal slider (track + handle) in GUI space. Assumes the caller manages
///       draw colour; restores it to c_white afterwards. Used by the F3 debug overlay.
/// @arg _x Track left
/// @arg _y Track centre line
/// @arg _w Track width
/// @arg _track_h Track thickness
/// @arg _handle_w Handle width
/// @arg _handle_h Handle height
/// @arg _t Normalised handle position 0-1
function debug_overlay_draw_slider(_x, _y, _w, _track_h, _handle_w, _handle_h, _t) {
	_t = clamp(_t, 0, 1);
	// Track
	draw_set_color(c_dkgray);
	draw_rectangle(_x, _y - _track_h * 0.5, _x + _w, _y + _track_h * 0.5, false);
	// Filled portion
	draw_set_color(c_ltgray);
	draw_rectangle(_x, _y - _track_h * 0.5, _x + _w * _t, _y + _track_h * 0.5, false);
	// Handle
	var _hx = _x + _w * _t;
	draw_set_color(c_white);
	draw_rectangle(_hx - _handle_w * 0.5, _y - _handle_h * 0.5, _hx + _handle_w * 0.5, _y + _handle_h * 0.5, false);
}

/// @desc Tint sprites in the world light map by the light level at a single sample point,
///       so the screen-space shadow pass darkens them uniformly instead of per-pixel.
///
///       The lighting subtracts the (blurred, inverted) light map over the whole frame, so a
///       cast shadow normally darkens whatever pixels are under it. Two cases look wrong:
///         - A character standing at a wall's base: the wall's shadow falls on its head.
///           Fix: sample the light at the character's feet and tint the whole sprite by it.
///         - A wall's front face (spr_wall image_index 1, used only where there's open floor
///           below): the wall is its own shadow caster, so the face it self-shadows and goes
///           dark even when a light is right in front of it. Fix: sample the lit floor just
///           below the wall and tint the tile by it, so the face shows when a light is near.
///
///       Must be called on a freshly composited light map (see obj_light_renderer Draw),
///       otherwise last frame's silhouettes would linger at stale positions.
///       Note: this does one surface_getpixel (a GPU readback / stall) per tinted sprite. Fine
///       for a screenful of actors + wall faces; if it ever shows up in the profiler, replace
///       the per-sprite reads with a single buffer_get_surface + buffer_peek.
/// @arg _camX The active camera's left edge in room space
/// @arg _camY The active camera's top edge in room space
function lightmap_tint_lit_sprites(_camX, _camY) {
	var _surf = global.worldShadowMap;
	if (_surf == undefined || !surface_exists(_surf)) return;

	var _sw = surface_get_width(_surf);
	var _sh = surface_get_height(_surf);

	// Pass 1: read the light at each sprite's sample point. These are GPU readbacks, so they
	// must happen before we set the surface as a render target below.
	//
	// Walls are never drawn in front of actors (that's why the scene doesn't bother depth-
	// sorting them), so we stamp all walls first as a flat "background" layer, then the actors
	// on top. Among themselves the actors are stamped back-to-front by y (matching depthsort),
	// so where two sprites overlap the one in front writes the light map last and wins --
	// otherwise a brighter sprite behind could bleed its light onto a darker one in front.

	// Front-facing walls: sample the floor a few pixels below the wall (in front of the face).
	// Walls tile a grid and don't overlap each other, so their order doesn't matter.
	var _wallStamps = [];
	with (obj_wall) {
		if (image_index != 1) continue;
		var _sx = floor((bbox_left + bbox_right) * 0.5 - _camX);
		var _sy = floor(bbox_bottom + 3 - _camY);
		if (_sx < 0 || _sy < 0 || _sx >= _sw || _sy >= _sh) continue;
		array_push(_wallStamps, { inst: id, col: surface_getpixel(_surf, _sx, _sy) });
	}

	// Dynamic actors: sample at the feet (the floor they stand on)
	var _actorStamps = [];
	var _actors = [obj_player, obj_helmet, obj_enemy, obj_enemy_ram,
		obj_spider, obj_spider_small, obj_bat];
	for (var a = 0; a < array_length(_actors); a++) {
		with (_actors[a]) {
			var _sx = floor((bbox_left + bbox_right) * 0.5 - _camX);
			var _sy = floor(bbox_bottom - 1 - _camY);
			if (_sx < 0 || _sy < 0 || _sx >= _sw || _sy >= _sh) continue;
			array_push(_actorStamps, { inst: id, col: surface_getpixel(_surf, _sx, _sy), sortY: y });
		}
	}
	array_sort(_actorStamps, function(_a, _b) { return _a.sortY - _b.sortY; });

	if (array_length(_wallStamps) == 0 && array_length(_actorStamps) == 0) return;

	// Pass 2: stamp each silhouette into the light map with its sampled light value (walls
	// first, then actors on top). gpu_set_fog(true, col, 0, 1) forces every drawn fragment to
	// `col` while keeping the sprite's alpha as a mask (same trick as drawFlashEffect), so only
	// the sprite's pixels are overwritten -- the surrounding floor light is left untouched.
	surface_set_target(_surf);
	gpu_set_blendmode(bm_normal);
	lightmap_stamp_sprites(_wallStamps, _camX, _camY);
	lightmap_stamp_sprites(_actorStamps, _camX, _camY);
	gpu_set_fog(false, c_white, 0, 0);
	surface_reset_target();
}

/// @desc Stamp a list of {inst, col} silhouettes into the currently targeted light map.
///       Assumes the caller has set the render target and bm_normal blend mode, and will
///       reset gpu_set_fog afterwards. See lightmap_tint_lit_sprites.
/// @arg _stamps Array of structs with .inst (instance id) and .col (light colour to flood with)
/// @arg _camX The active camera's left edge in room space
/// @arg _camY The active camera's top edge in room space
function lightmap_stamp_sprites(_stamps, _camX, _camY) {
	var _n = array_length(_stamps);
	for (var i = 0; i < _n; i++) {
		gpu_set_fog(true, _stamps[i].col, 0, 1);
		with (_stamps[i].inst) {
			draw_sprite_ext(sprite_index, image_index, x - _camX, y - _camY,
				image_xscale, image_yscale, image_angle, c_white, 1);
		}
	}
}