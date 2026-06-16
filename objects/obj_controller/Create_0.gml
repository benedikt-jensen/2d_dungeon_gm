camera_target = instance_create_layer(0,0,layer,obj_camera_target);
move_to_center(camera_target, objects_of_type(obj_player));

for (var i = 0; i < 15; i++) {
    if (gamepad_is_connected(i)) {
        show_debug_message("Gamepad " + string(i) + " connected: " + gamepad_get_description(i));
    }
}

global.gameOver = false;
global.keyFound = false;
global.currentLevel = 0;
global.masterVolume= 1;

nextLevel();