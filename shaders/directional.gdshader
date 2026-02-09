shader_type spatial;

uniform float amplitude = 0.5;
uniform float wavelength = 10.0;
uniform float steepness = 0.5; // Keep between 0 and 1
uniform vec2 direction = vec2(1.0, 0.0);
uniform float speed = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
    
    float k = 2.0 * PI / wavelength;
    float f = k * (dot(normalize(direction), VERTEX.xz) - TIME * speed);
    float a = amplitude;
    
    // Horizontal Displacement (Crest Sharpening)
    vec2 d = normalize(direction);
    VERTEX.x += d.x * (steepness * a) * cos(f);
    VERTEX.z += d.y * (steepness * a) * cos(f);
    
    // Vertical Displacement
    VERTEX.y = a * sin(f);
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
