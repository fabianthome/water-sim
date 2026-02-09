shader_type spatial;

uniform vec3 center = vec3(0.0, 0.0, 0.0);
uniform float amplitude = 0.3;
uniform float wavelength = 2.0;
uniform float speed = 2.0;
uniform float decay = 0.5; // Waves get smaller as they move away

void vertex() {
	// Called for every vertex the material is visible on.
    
    // Calculate distance from the center point in the XZ plane
    float dist = distance(VERTEX.xz, center.xz);
    
    float k = 2.0 * PI / wavelength;
    float f = k * (dist - TIME * speed);
    
    // Apply amplitude with an optional decay based on distance
    float current_amp = amplitude / (1.0 + dist * decay);
    
    // Vertical Displacement
    VERTEX.y = current_amp * sin(f);
    
    // Optional: Radial "peaking" (Gerstner style for ripples)
    // This pulls vertices toward the center of the ripple crests
    vec2 dir_from_center = normalize(VERTEX.xz - center.xz);
    VERTEX.xz -= dir_from_center * (current_amp * 0.5) * cos(f);
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
