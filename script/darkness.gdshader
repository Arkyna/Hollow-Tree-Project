shader_type canvas_item;

uniform vec2 light_position;
uniform float light_radius = 240.0;
uniform float cone_angle = 0.55;
uniform float cone_direction = 0.0;

void fragment() {
    vec2 uv = FRAGCOORD.xy;
    vec2 dir = normalize(uv - light_position);

    // angle difference between cone direction and this pixel
    float angle_diff = acos(dot(dir, vec2(cos(cone_direction), sin(cone_direction))));

    // inside the cone?
    float in_cone = float(angle_diff < cone_angle);

    float dist = distance(uv, light_position);

    float visibility = smoothstep(light_radius, light_radius * 0.6, dist) * in_cone;

    vec4 darkness = vec4(0.0, 0.0, 0.0, 0.88);

    COLOR = mix(darkness, vec4(0.0), visibility);
}
