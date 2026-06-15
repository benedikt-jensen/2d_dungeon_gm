///voron_init()
function voron_init() {
	//Set up the Voronoi Split-Screen System.
	gml_pragma("global","voron_init()") //Set up these global variables before the first room (since we only have one room in this demo)
										//Feel free to call this manually and remove this pragma if you want more control.

	//Number of players
#macro voron_DEBUG_INFORMATION false
#macro voron_OBJECTS_MAX 4
	global.voron_number_of_players = 1

#macro VIEW_W camera_get_view_width(view_camera[0])
#macro VIEW_H camera_get_view_height(view_camera[0])

//#macro VIEW_W 1280
//#macro VIEW_H 708

	//Lerping factor when smoothly moving positions
	global.voron_lerp_world  = 0.1
	global.voron_lerp_view   = 0.05

	//Split-screen is experimental, so it's off by default. When off we set the merge distance
	//to infinity: every player batches into a single view centred on their centroid, the
	//merger shader draws view 0 fullscreen, and the screen never splits -- while the camera
	//still follows the characters exactly as before. Toggle it with voron_set_splitscreen().
	global.voron_splitscreen_enabled  = false
	global.voron_split_distance       = 200		//Distance where views split apart, when enabled
	global.voron_combination_distance = global.voron_splitscreen_enabled ? global.voron_split_distance : infinity

	//Debug overlay (top-right checkbox, toggled with F3)
	global.show_voron_debug = false

	//Positions for all players
	for(var c = 0; c < voron_OBJECTS_MAX; c++){
		global.voron_worldpos_x[c]		= 0		//GM position in the room
		global.voron_worldpos_y[c]		= 0
		global.voron_rawscreenpos_x[c]	= 0.5	//Screen position as-is
		global.voron_rawscreenpos_y[c]	= 0.5
		global.voron_screenpos_x[c]		= 0.5	//Normalized and balanced screen position
		global.voron_screenpos_y[c]		= 0.5
		global.voron_tlc_x[c]			= 0		//Top Left Corner (view position)
		global.voron_tlc_y[c]			= 0
	}


}

/// @desc Enable or disable Voronoi split-screen at runtime. When disabled the merge distance
///       becomes infinite, so all players collapse into a single view (the screen never
///       splits); when enabled it returns to the normal split distance.
/// @arg _enabled Whether split-screen should be active
function voron_set_splitscreen(_enabled) {
	global.voron_splitscreen_enabled  = _enabled;
	global.voron_combination_distance = _enabled ? global.voron_split_distance : infinity;
}
