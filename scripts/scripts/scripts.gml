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

/// @desc Tint character sprites in the world light map by the light level at their feet.
///       The lighting is a screen-space pass that subtracts the (blurred, inverted) light
///       map over the whole frame, so a wall's cast shadow normally darkens whatever pixels
///       are under it -- including a character standing at the wall's base, whose head
///       overlaps the wall and gets the shadow drawn over it. By overwriting each character's
///       silhouette in the light map with a single value sampled at its feet, the subtract
///       pass darkens the whole sprite uniformly (lit if the feet are lit) instead of
///       per-pixel, so it no longer picks up the wall's shadow on its head.
///       Must be called on a freshly composited light map (see obj_light_renderer Draw),
///       otherwise last frame's silhouettes would linger at stale positions.
/// @arg _camX The active camera's left edge in room space
/// @arg _camY The active camera's top edge in room space
function lightmap_tint_characters(_camX, _camY) {
	var _surf = global.worldShadowMap;
	if (_surf == undefined || !surface_exists(_surf)) return;

	// Dynamic actors that should be lit by their feet, not per-pixel
	var _actors = [obj_player, obj_helmet, obj_enemy, obj_enemy_ram,
		obj_spider, obj_spider_small, obj_bat];

	var _sw = surface_get_width(_surf);
	var _sh = surface_get_height(_surf);

	// Pass 1: read the light at each actor's feet. This is a GPU readback, so it must happen
	// before we set the surface as a render target below.
	var _ids = [];
	var _cols = [];
	for (var a = 0; a < array_length(_actors); a++) {
		with (_actors[a]) {
			var _fx = floor((bbox_left + bbox_right) * 0.5 - _camX);
			var _fy = floor(bbox_bottom - 1 - _camY);
			if (_fx < 0 || _fy < 0 || _fx >= _sw || _fy >= _sh) continue;
			array_push(_ids, id);
			array_push(_cols, surface_getpixel(_surf, _fx, _fy));
		}
	}

	var _n = array_length(_ids);
	if (_n == 0) return;

	// Pass 2: stamp each actor's silhouette into the light map with its feet light value.
	// gpu_set_fog(true, col, 0, 1) forces every drawn fragment to `col` while keeping the
	// sprite's alpha as a mask (same trick as drawFlashEffect), so only the character's
	// pixels are overwritten -- the surrounding floor light is left untouched.
	surface_set_target(_surf);
	gpu_set_blendmode(bm_normal);
	for (var i = 0; i < _n; i++) {
		gpu_set_fog(true, _cols[i], 0, 1);
		with (_ids[i]) {
			draw_sprite_ext(sprite_index, image_index, x - _camX, y - _camY,
				image_xscale, image_yscale, image_angle, c_white, 1);
		}
	}
	gpu_set_fog(false, c_white, 0, 0);
	surface_reset_target();
}