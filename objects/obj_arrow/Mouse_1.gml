if(travelTime <= 0) {
	if(point_distance(obj_player.x, obj_player.y, x+lengthdir_x(8,image_angle), y+lengthdir_y(8,image_angle)) < 30) {
		audio_play_sound(snd_pick_up_arrow_2,0,0)
		instance_destroy();
		obj_player.arrows++;
	}
}