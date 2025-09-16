shader_type spatial;
render_mode unshaded, cull_front, depth_draw_always, blend_mix, fog_disabled;

uniform float fog_near = 200.0;   // distance where fog starts
uniform float fog_far = 600.0;    // distance where fog is fully opaque
uniform vec4 fog_color : source_color = vec4(0.5, 0.6, 0.8, 1.0); // fog color

void fragment() {
    // VIEW is the vector from fragment to camera in world space
    float dist = length(VIEW);

    // fog factor
    float fog = smoothstep(fog_near, fog_far, dist);

    // Just render fog color with fade
    ALBEDO = fog_color.rgb;
    ALPHA = fog;
}
