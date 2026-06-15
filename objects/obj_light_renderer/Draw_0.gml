/// @desc Lighting

// Get the active camera (in split-screen each view has its own camera)
var camera = lighting_get_active_camera();

// The shadow map is composited in camera/screen space, so it is only valid for the
// camera it was built with. With multiple views (e.g. Voronoi split-screen) the Draw
// event runs once per view, so we must rebuild the shadow map whenever the active
// camera changes - not just when the per-frame update tick elapses - otherwise every
// view after the first reuses the first view's shadow map and lighting looks broken.
var cameraChanged = (camera[eLightingCamera.X]      != last_camera_x)
				 || (camera[eLightingCamera.Y]      != last_camera_y)
				 || (camera[eLightingCamera.Width]  != last_camera_w)
				 || (camera[eLightingCamera.Height] != last_camera_h);

// Update the shadow map
var exists;

if(dirty || cameraChanged || tick >= global.lightUpdateFrameDelay || global.worldShadowMap == undefined || !surface_exists(global.worldShadowMap)) {
	// Composite shadow map
	exists = composite_shadow_map(global.worldLights);
	dirty = false;
	tick = 0;

	// Remember the camera this shadow map was composited for
	last_camera_x = camera[eLightingCamera.X];
	last_camera_y = camera[eLightingCamera.Y];
	last_camera_w = camera[eLightingCamera.Width];
	last_camera_h = camera[eLightingCamera.Height];
}
else exists = surface_exists(global.worldShadowMap);

if(exists) {
	// Draw the shadow map
	draw_shadow_map(camera[eLightingCamera.X], camera[eLightingCamera.Y]);
}