//Batch players together
//(The idea is that players that are near enough will have the same position, thus getting the same view implicitly.)
var batches = [], meanies = [];
with(parent_player){
	batched = false;
}
for(var c = 0; c < voron_OBJECTS_MAX - 1; c++){ //-1 since the last object doesn't have any objects of higher IDs to batch with, so it would only find batches containing itself.
	var  cobj = voron_player_get_id(c);
	var  thisbatch = [];
	var  thismean_x  = 0, thismean_y = 0, thisfound = 0;
	with(cobj){
		if(!batched){
			with(parent_player){
				if(player_id > other.player_id && !batched){
					if(point_distance(x,y,other.x,other.y) < global.voron_combination_distance){
						thisbatch[array_length_1d(thisbatch)] = player_id
						batched = true
					
						thisfound++
						thismean_x += x
						thismean_y += y
					}
				}
			}
			if(thisfound > 0){
				//Add myself too at the end, but only if batch had anything
				thisfound++
				thismean_x += x
				thismean_y += y
				thisbatch[array_length_1d(thisbatch)] = player_id
			
				//Make actual mean
				thismean_x /= thisfound
				thismean_y /= thisfound
			
				//Enqueue
				batches[array_length_1d(batches)] = thisbatch
				meanies[array_length_1d(meanies)] = [thismean_x,thismean_y]
			
				batched = true
			}
		}
	}
}


//Apply batches
for(var c = 0; c < array_length_1d(batches); c++){
	var data	= batches[c];
	var coords	= meanies[c];
	for(var d = 0; d < array_length_1d(data); d++){
		var dd = data[d];
		global.voron_worldpos_x[	dd] = lerp(global.voron_worldpos_x[		dd], coords[0],				global.voron_lerp_world)
		global.voron_worldpos_y[	dd] = lerp(global.voron_worldpos_y[		dd], coords[1],				global.voron_lerp_world)
		global.voron_rawscreenpos_x[dd] = lerp(global.voron_rawscreenpos_x[	dd], coords[0]/room_width,	global.voron_lerp_view)
		global.voron_rawscreenpos_y[dd] = lerp(global.voron_rawscreenpos_y[	dd], coords[1]/room_height, global.voron_lerp_view)
	}
}

//If not in a batch, just target actual position.
with(parent_player){
	if(!batched){
		global.voron_worldpos_x[	player_id]	= lerp(global.voron_worldpos_x[		player_id], x,				global.voron_lerp_world)
		global.voron_worldpos_y[	player_id]	= lerp(global.voron_worldpos_y[		player_id], y,				global.voron_lerp_world)
		global.voron_rawscreenpos_x[player_id]	= lerp(global.voron_rawscreenpos_x[	player_id], x/room_width,	global.voron_lerp_view)
		global.voron_rawscreenpos_y[player_id]	= lerp(global.voron_rawscreenpos_y[	player_id], y/room_height,	global.voron_lerp_view)
	}
}

//Compute screen positions using relative orientation
var acc_x = 0, acc_y = 0, acc = 0, min_x = 1, min_y = 1, max_x = 0, max_y = 0, mean_x = 0.5, mean_y = 0.5;
for(var c = 0; c < global.voron_number_of_players; c++){
	acc++
	acc_x +=			global.voron_rawscreenpos_x[c]
	acc_y +=			global.voron_rawscreenpos_y[c]
	min_x  = min(min_x, global.voron_rawscreenpos_x[c])
	min_y  = min(min_y, global.voron_rawscreenpos_y[c])
	max_x  = max(max_x, global.voron_rawscreenpos_x[c])
	max_y  = max(max_y, global.voron_rawscreenpos_y[c])
}
if(acc > 0){
	mean_x = acc_x/acc
	mean_y = acc_y/acc
}

//Compute distances for normalization purposes
var delta_x = max_x - min_x, delta_y = max_y - min_y, relex_x, relex_y, xf = 0.5, yf = 0.5;

//Normalization gets really janky when distances are small, where the view will instantly jump angles at the zero crossing, so have a lower cap.
if(delta_x != 0){delta_x = max(delta_x,0.2)}
if(delta_y != 0){delta_y = max(delta_y,0.2)}

//Use screen position to update view
for(var c = 0; c < global.voron_number_of_players; c++){
	if(abs(delta_x) == 0){ relex_x = 0.5 }else{ relex_x	= 0.5 + lerp(0,0.5,		  (	global.voron_rawscreenpos_x[c] - mean_x)/delta_x) }
	if(abs(delta_y) == 0){ relex_y = 0.5 }else{ relex_y	= 0.5 + lerp(0,0.5,		  (	global.voron_rawscreenpos_y[c] - mean_y)/delta_y) }
	global.voron_screenpos_x[c] = lerp(global.voron_screenpos_x[c], relex_x, global.voron_lerp_view)
	global.voron_screenpos_y[c] = lerp(global.voron_screenpos_y[c], relex_y, global.voron_lerp_view)
	xf = global.voron_screenpos_x[c]
	yf = global.voron_screenpos_y[c]
	
	show_debug_message(string(c) + ": " + string(xf) + " x " + string(yf))

	global.voron_tlc_x[c] = clamp(global.voron_worldpos_x[c] - VIEW_W*xf,0,room_width  - VIEW_W)
	global.voron_tlc_y[c] = clamp(global.voron_worldpos_y[c] - VIEW_H*yf,0,room_height - VIEW_H)
	
	camera_set_view_pos(view_camera[c],global.voron_tlc_x[c],global.voron_tlc_y[c])
	
	//Ensure that the surfaces exists
	if(!surface_exists(view_surface_id[c])){
		view_surface_id[c]	= surface_create(VIEW_W,VIEW_H)
	}
}