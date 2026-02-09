shader_type spatial;

group_uniforms Look;
uniform vec3 water_color : source_color = vec3(0.01, 0.05, 0.1);
// uniform vec3 bubble_color : source_color = vec3(0.5, 0.7, 1.0);
uniform float shininess : hint_range(1.0, 1024.0) = 64.0;
uniform vec3 specular_color : source_color = vec3(1.0);

group_uniforms Waves;
uniform int wave_count : hint_range(1, 4) = 3;
// TODO: wave_data: x,y = direction | z = steepness (Q) | w = amplitude (A)
uniform vec4 wave_1 = vec4(1.0, 0.0, 0.5, 0.2); 
uniform vec4 wave_2 = vec4(0.7, 0.7, 0.3, 0.1);
uniform vec4 wave_3 = vec4(-0.2, 0.8, 0.2, 0.05);

// wave_params: x = wavelength (L) | y = speed (phi)
uniform vec2 params_1 = vec2(4.0, 0.5);
uniform vec2 params_2 = vec2(2.5, 1.0);
uniform vec2 params_3 = vec2(1.2, 0.5);

// Implementation of the Gerstner Wave Summation
void calculate_wave(vec4 wave, vec2 params, vec3 p, float time, inout vec3 offset, inout vec3 tangent, inout vec3 binormal) {
    float l = params.x;
    float k = 2.0 * PI / l; // wavenumber
    float a = wave.w;       // amplitude
    float q = wave.z;       // steepness
    vec2 d = normalize(wave.xy); // direction
    
    // The Phase: k * (D dot xz) - (speed * t)
    float f = k * (dot(d, p.xz) - (params.y * time));
    
    float cos_f = cos(f);
    float sin_f = sin(f);

    // Horizontal and Vertical Displacement
    offset.x += d.x * (q * a) * cos_f;
    offset.z += d.y * (q * a) * cos_f;
    offset.y += a * sin_f;

    // Manual Normal Reconstruction via Partial Derivatives
    // Calculate Tangent and Binormal
    float wa = k * a;
    tangent += vec3(
        -d.x * d.x * (q * wa) * sin_f,
        d.x * wa * cos_f,
        -d.x * d.y * (q * wa) * sin_f
    );
    binormal += vec3(
        -d.x * d.y * (q * wa) * sin_f,
        d.y * wa * cos_f,
        -d.y * d.y * (q * wa) * sin_f
    );
}

void vertex() {
    // Called for every vertex the material is visible on.
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec3 offset = vec3(0.0);
    
    // Initialize vectors for Cross Product Normal
    vec3 tangent = vec3(1.0, 0.0, 0.0);
    vec3 binormal = vec3(0.0, 0.0, 1.0);

    // TODO: Summing multiple waves for "Statistical" look
    calculate_wave(wave_1, params_1, world_pos, TIME, offset, tangent, binormal);
    if (wave_count > 1) calculate_wave(wave_2, params_2, world_pos, TIME, offset, tangent, binormal);
    if (wave_count > 2) calculate_wave(wave_3, params_3, world_pos, TIME, offset, tangent, binormal);

    VERTEX += offset;
    
    // Update NORMAL so Godot's light engine works with the displaced vertices (enabling self-shadowing)
    NORMAL = normalize(cross(binormal, tangent));
}

void fragment() {
    // Called for every pixel the material is visible on.
    ALBEDO = water_color;
    ROUGHNESS = 0.05;
    METALLIC = 0.2;
}

void light() {
    // Called for every pixel for every light affecting the material.
    // Calculate the Halfway Vector (H)
    vec3 halfway = normalize(LIGHT + VIEW);

    // Lambertian Diffuse
    float n_dot_l = max(dot(NORMAL, LIGHT), 0.0);
    vec3 diffuse = ALBEDO * LIGHT_COLOR * n_dot_l * ATTENUATION;
    DIFFUSE_LIGHT += diffuse;

    // Specular Highlight (Blinn-Phong)
    float n_dot_h = max(dot(NORMAL, halfway), 0.0);
    float spec_amount = pow(n_dot_h, shininess);

    // Fresnel Reflectivity
    float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 5.0);

    vec3 specular = specular_color * LIGHT_COLOR * spec_amount * ATTENUATION;
    SPECULAR_LIGHT += specular * mix(0.1, 1.0, fresnel);
}
