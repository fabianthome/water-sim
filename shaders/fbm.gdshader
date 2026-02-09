shader_type spatial;

group_uniforms Look;
uniform vec3 water_color : source_color = vec3(0.01, 0.05, 0.1);
uniform float shininess : hint_range(1.0, 1024.0) = 128.0;
uniform vec3 specular_color : source_color = vec3(1.0);

group_uniforms FBM_Parameters;
uniform int octaves : hint_range(1, 8) = 5;
uniform float lacunarity : hint_range(1.0, 4.0) = 2.0; // frequency multiplier per octave
uniform float gain : hint_range(0.0, 1.0) = 0.5; // amplitude multiplier per octave
uniform float hurst : hint_range(0.1, 0.9) = 0.1; // Hurst exponent for roughness control
uniform float initial_frequency = 0.2;
uniform float initial_amplitude = 0.5;
uniform float speed = 1.0;
// domain warping
uniform float warp_strength : hint_range(0.0, 5.0) = 1.0;
uniform float warp_frequency = 0.15;

// simple hash function for noise generation
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// 2D noise function
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // cubic interpolation

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// calc FBM height and analytical normal
void calculate_fbm(vec3 p, float time, out float height, out vec3 normal) {
	// domain warping
	// offset coords by noise to create turbulence
	vec2 warp_offset;
	warp_offset.x = noise(p.xz * warp_frequency + (time * 0.2));
	warp_offset.y = noise(p.zx * warp_frequency - (time * 0.25));
	
	// apply warp to primary sampling coord
	vec2 warped_p = p.xz + (warp_offset * warp_strength);

	// FBM loop
	float amp = initial_amplitude;
	float freq = initial_frequency;
	height = 0.0;
	float dx = 0.0;
	float dz = 0.0;

	for (int i = 0; i < octaves; i++) {
		// slight speed shift per octave to simulate different wind layers
		vec2 sample_pos = warped_p * freq + (time * speed * (1.0 + float(i)*0.1));
		float n = noise(sample_pos);
		
		height += n * amp;
		
		// finite difference for normal
		float eps = 0.01;
		float n_dx = (noise(sample_pos + vec2(eps, 0.0)) - n) / eps;
		float n_dz = (noise(sample_pos + vec2(0.0, eps)) - n) / eps;
		
		dx += n_dx * amp * freq;
		dz += n_dz * amp * freq;
		
		// amp *= gain;
		amp *= gain * pow(2.0, -hurst);
		freq *= lacunarity;
	}
	
	normal = normalize(vec3(-dx, 1.0, -dz));
}

void vertex() {
	// Called for every vertex the material is visible on.
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h;
	vec3 n;

	calculate_fbm(world_pos, TIME, h, n);

	VERTEX.y += h;

	NORMAL = (MODEL_NORMAL_MATRIX * n);
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = water_color;
	ROUGHNESS = 0.05;
	METALLIC = 0.2;
}

void light() {
	// Called for every pixel for every light affecting the material.
	vec3 halfway = normalize(LIGHT + VIEW);

	// Lambertian Diffuse
	float n_dot_l = max(dot(NORMAL, LIGHT), 0.0);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * n_dot_l * ATTENUATION;

	// Specular Highlight (Blinn-Phong)
	float n_dot_h = max(dot(NORMAL, halfway), 0.0);
	float spec_amount = pow(n_dot_h, shininess);

	// Fresnel Reflectivity
	float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 5.0);

	vec3 specular = specular_color * LIGHT_COLOR * spec_amount * ATTENUATION;
	SPECULAR_LIGHT += specular * mix(0.1, 1.0, fresnel);
}