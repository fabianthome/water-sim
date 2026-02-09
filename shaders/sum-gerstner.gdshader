shader_type spatial;

// Each vec4 represents: x,z = Direction | w = Steepness | y = Amplitude
uniform vec4 wave1 = vec4(1.0, 0.0, 0.4, 0.2);
uniform vec4 wave2 = vec4(0.7, 0.7, 0.3, 0.1);
uniform vec4 wave3 = vec4(0.0, 1.0, 0.2, 0.05);

uniform float wavelength1 = 4.0;
uniform float wavelength2 = 2.5;
uniform float wavelength3 = 1.2;

uniform float speed = 1.0;

// Function to calculate a single Gerstner Wave's contribution
// Returns: .xyz = position offset, .normal_math_helper = used for normal calc
void calculate_gerstner(vec4 wave, float wavelength, vec3 grid_pos, float time, 
                        inout vec3 offset, inout vec3 tangent, inout vec3 binormal) {
    
    float steepness = wave.z;
    float amplitude = wave.w;
    vec2 d = normalize(wave.xy);
    float k = 2.0 * PI / wavelength;
    float f = k * (dot(d, grid_pos.xz) - speed * time);
    
    float a = amplitude;
    
    // Position Offset (GPU Gems Eq. 1)
    offset.x += d.x * (steepness * a) * cos(f);
    offset.y += a * sin(f);
    offset.z += d.y * (steepness * a) * cos(f);
    
    // Partial Derivatives for Normals (GPU Gems Eq. 10-12)
    float wa = k * a;
    tangent += vec3(
        -d.x * d.x * (steepness * wa) * sin(f),
        d.x * wa * cos(f),
        -d.x * d.y * (steepness * wa) * sin(f)
    );
    binormal += vec3(
        -d.x * d.y * (steepness * wa) * sin(f),
        d.y * wa * cos(f),
        -d.y * d.y * (steepness * wa) * sin(f)
    );
}

void vertex() {
	// Called for every vertex the material is visible on.
    
    vec3 grid_pos = VERTEX;
    vec3 offset = vec3(0.0);
    
    // Initialize tangent and binormal as basis vectors
    vec3 tangent = vec3(1.0, 0.0, 0.0);
    vec3 binormal = vec3(0.0, 0.0, 1.0);
    
    // Sum the waves
    calculate_gerstner(wave1, wavelength1, grid_pos, TIME, offset, tangent, binormal);
    calculate_gerstner(wave2, wavelength2, grid_pos, TIME, offset, tangent, binormal);
    calculate_gerstner(wave3, wavelength3, grid_pos, TIME, offset, tangent, binormal);
    
    VERTEX += offset;
    
    // The Normal is the cross product of the accumulated tangent and binormal
    NORMAL = normalize(cross(binormal, tangent));
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
