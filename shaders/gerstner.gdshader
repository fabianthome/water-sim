shader_type spatial;

group_uniforms Look;
uniform vec3 water_color : source_color = vec3(0.01, 0.05, 0.1);
// uniform vec3 bubble_color : source_color = vec3(0.5, 0.7, 1.0);
uniform float shininess : hint_range(1.0, 1024.0) = 64.0;
uniform vec3 specular_color : source_color = vec3(1.0);

group_uniforms Wave;
uniform vec2 direction = vec2(1.0, 0.0); // wavevector k direction
uniform float amplitude = 0.5;           // amplitude a
uniform float wavelength = 4.0;          // wavelength lambda
uniform float steepness = 0.5;           // ka (dimensionless amplitude/steepness)
uniform float speed = 0.7;               // frequency omega (via dispersion)

void vertex() {
    // Called for every vertex the material is visible on.

    // Wavevector k
    float k = 2.0 * PI / wavelength;
    vec2 d = normalize(direction);
    
    // Phase
    float phase = k * (dot(d, VERTEX.xz) - (speed * TIME));
    
    // Displacement Logic
    vec3 displacement;
    
    // TODO: Horizontal Displacement (!)
    displacement.x = -d.x * (steepness * amplitude) * sin(phase);
    displacement.z = -d.y * (steepness * amplitude) * sin(phase);
    
    // Vertical Displacement
    displacement.y = amplitude * cos(phase);

    // Normal Reconstruction
    float wa = k * amplitude;
    float s = sin(phase);
    float c = cos(phase);

    // Tangent and Binormal calculation for a Trochoidal surface
    vec3 tangent = vec3(
        1.0 - d.x * d.x * wa * c,
        d.x * wa * s,
        -d.x * d.y * wa * c
    );
    vec3 binormal = vec3(
        -d.x * d.y * wa * c,
        d.y * wa * s,
        1.0 - d.y * d.y * wa * c
    );

    VERTEX += displacement;
    
    // Update Normal to ensure lighting/shadows work
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

