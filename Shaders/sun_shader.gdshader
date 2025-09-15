shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;

uniform vec4 color_top : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform vec4 color_bottom : source_color = vec4(1.0, 0.0, 0.6, 1.0);
uniform float intensity : hint_range(0.0, 10.0) = 2.0;

uniform int num_lines : hint_range(1, 20) = 7;
uniform float line_height_min : hint_range(0.0, 1.0) = 0.01;
uniform float line_height_max : hint_range(0.0, 1.0) = 0.15;
uniform float speed : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    // Remap UVs so (0.5,0.5) is center
    vec2 uv = UV * 2.0 - 1.0;
    float r = length(uv);

    // Circle mask (soft edge)
    if (r > 1.0) {
        discard;
    }

    // Vertical gradient inside circle
    float t = clamp(uv.y * 0.5 + 0.5, 0.0, 1.0);
    vec3 gradient_color = mix(color_bottom.rgb, color_top.rgb, t);

    // Moving horizontal line cutouts
    float alpha = 1.0;
    float moving_position = mod(TIME * speed, 1.0 + line_height_max);

    for (int i = 0; i < num_lines; i++) {
        float line_position = mod(moving_position + float(i) / float(num_lines), 
                                  1.0 + line_height_max) - line_height_max;

        float line_height = mix(line_height_max, line_height_min, 
                                clamp(line_position, 0.0, 1.0));

        // Remove stripes
        float line_alpha = smoothstep(line_position - line_height/2.0,
                                      line_position + line_height/2.0, uv.y*0.5+0.5)
                         - smoothstep(line_position + line_height/2.0,
                                      line_position + line_height/2.0 + 0.01, uv.y*0.5+0.5);

        alpha *= (1.0 - line_alpha);
    }

    ALBEDO = gradient_color;
    EMISSION = gradient_color * intensity;
    ALPHA = alpha;
}
