shader_type spatial;

uniform vec4 wave_a = vec4(1.0, 1.0, 0.2, 2.0); // x,z: direction, w: amplitude, z: frequency
uniform vec4 wave_b = vec4(1.0, 0.6, 0.1, 3.0);
uniform vec4 wave_c = vec4(-0.5, 1.0, 0.04, 5.0);
uniform vec4 wave_d = vec4(0.2, -1.0, 0.06, 1.5);

// Function to calculate a single sine wave displacement
float calculate_sine(vec2 pos, float time, vec4 wave_params) {
    vec2 d = normalize(wave_params.xy);
    float amplitude = wave_params.z;
    float frequency = wave_params.w;
    
    // The sine function
    return amplitude * sin(dot(d, pos) * frequency + time);
}

void vertex() {
	// Called for every vertex the material is visible on.
    
    vec2 pos = VERTEX.xz;
    float t = TIME;
    
    // Sum the waves
    float height = 0.0;
    height += calculate_sine(pos, t, wave_a);
    height += calculate_sine(pos, t, wave_b);
    height += calculate_sine(pos, t, wave_c);
    height += calculate_sine(pos, t, wave_d);
    
    // Apply displacement
    VERTEX.y += height;
    
    // Note: For realistic lighting, you would also need to sum the 
    // partial derivatives to calculate the new NORMAL here.
}

void fragment() {
	// Called for every pixel the material is visible on.
    // Basic water-like visual
    ALBEDO = vec3(0.1, 0.3, 0.5);
    ROUGHNESS = 0.1;
    SPECULAR = 0.8;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
