shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;

uniform vec4 color_top : source_color = vec4(1.0, 0.8, 0.2, 1.0); // yellow
uniform vec4 color_bottom : source_color = vec4(1.0, 0.0, 0.6, 1.0); // pink
uniform int num_stripes : hint_range(1, 20) = 10;
uniform float stripe_softness : hint_range(0.0, 0.2) = 0.25;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0; // center in [-1,1]
    float r = length(uv);

    // circle mask
    if (r > 1.0) {
        discard;
    }

    // vertical gradient
    float t = clamp(uv.y * 0.5 + 0.5, 0.0, 1.0);
    vec3 grad = mix(color_bottom.rgb, color_top.rgb, t);

    // horizontal stripes
    float stripe = fract(t * float(num_stripes));
    float mask = smoothstep(0.0, stripe_softness, stripe) * (1.0 - smoothstep(1.0 - stripe_softness, 1.0, stripe));

    vec3 col = grad * mask;

    ALBEDO = col;
    EMISSION = col;
    ALPHA = 1.0;
}
