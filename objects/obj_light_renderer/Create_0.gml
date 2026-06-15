/// @desc Setup renderer

tick = 0;
dirty = false;
global.ambientShadowIntensity = ambient_shadow;

// Camera the shadow map was last composited for; used to detect view changes
// (e.g. split-screen) so the shadow map is rebuilt per view. Start invalid so
// the first draw always composites.
last_camera_x = undefined;
last_camera_y = undefined;
last_camera_w = undefined;
last_camera_h = undefined;
