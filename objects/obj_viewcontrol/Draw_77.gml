//Manually draw the app surface!
shader_set(sh_voronoimerger)
{
	var pos = [
		global.voron_screenpos_x[0],
		global.voron_screenpos_y[0],
		global.voron_screenpos_x[1],
		global.voron_screenpos_y[1],
		global.voron_screenpos_x[2],
		global.voron_screenpos_y[2],
		global.voron_screenpos_x[3],
		global.voron_screenpos_y[3]
	];
	
	shader_set_uniform_i(		u_voron_num,global.voron_number_of_players)
	shader_set_uniform_f_array(	u_voron_pos,pos)
	
	var s = surface_get_texture(view_surface_id[0]);
	if(global.voron_number_of_players > 1){ texture_set_stage(u_voron_t1,surface_get_texture(view_surface_id[1])) }else{ texture_set_stage(u_voron_t1,s) }
	if(global.voron_number_of_players > 2){ texture_set_stage(u_voron_t2,surface_get_texture(view_surface_id[2])) }else{ texture_set_stage(u_voron_t2,s) }
	if(global.voron_number_of_players > 3){ texture_set_stage(u_voron_t3,surface_get_texture(view_surface_id[3])) }else{ texture_set_stage(u_voron_t3,s) }
	
	
	//Everything is ready! Actually draw...
	var _xscale = display_get_gui_width() / surface_get_width(view_surface_id[0]);
	var _yscale = display_get_gui_height() / surface_get_height(view_surface_id[0]);
	draw_surface_ext(view_surface_id[0],0,0,_xscale,_yscale,0,c_white,1);
}
shader_reset()