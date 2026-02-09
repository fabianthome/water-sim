shader_type spatial;

group_uniforms Look;
uniform vec3 water_color : source_color = vec3(0.01, 0.05, 0.1);
// uniform vec3 bubble_color : source_color = vec3(0.5, 0.7, 1.0);
uniform float shininess : hint_range(1.0, 1024.0) = 64.0;
uniform vec3 specular_color : source_color = vec3(1.0);

void vertex() {
    // Called for every vertex the material is visible on.
}

void fragment() {
    // Called for every pixel the material is visible on.
    ALBEDO = water_color;
    ROUGHNESS = 0.05;
    METALLIC = 0.2;
}

void light() {
    // Called for every pixel for every light affecting the material.
    // calc Halfway Vector (H)
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
