shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley;

// --- STRUCTURES ---

struct Wave {
	vec2 direction;
	vec2 origin;
	float frequency;
	float amplitude;
	float phase;
	float steepness;
};

// --- CONSTANTS ---

const int MAX_WAVES = 10;
// const float PI = 3.14159265359;

// --- UNIFORMS (PROPERTIES) ---

group_uniforms Features;
uniform bool use_vertex_displacement = true;
uniform bool use_fbm = false;
uniform int wave_type : hint_range(0, 2) = 0; // 0: Sine, 1: Steep Sine, 2: Gerstner
uniform bool circular_waves = false;
uniform bool normals_in_pixel_shader = false;

group_uniforms Waves;
uniform int wave_count = 1;
// Note: In Godot, we cannot export arrays of structs to the inspector easily yet.
// You usually set these via script or use individual arrays. 
// For this shader, we define defaults for index 0 to work out-of-the-box.
uniform vec2 wave_0_direction = vec2(1.0, 0.0);
uniform float wave_0_amplitude = 0.5;
uniform float wave_0_frequency = 1.0;
uniform float wave_0_speed = 1.0;
uniform float wave_0_steepness = 1.0;

group_uniforms VertexFBM;
uniform float v_fbm_seed = 0.0;
uniform int v_fbm_wave_count = 4;
uniform float v_fbm_frequency = 1.0;
uniform float v_fbm_frequency_mult = 2.0;
uniform float v_fbm_amplitude = 0.5;
uniform float v_fbm_amplitude_mult = 0.5;
uniform float v_fbm_initial_speed = 1.0;
uniform float v_fbm_speed_ramp = 1.0;
uniform float v_fbm_drag = 0.0;
uniform float v_fbm_height = 1.0;
uniform float v_fbm_max_peak = 1.0;
uniform float v_fbm_peak_offset = 0.0;

group_uniforms FragmentFBM;
uniform float f_fbm_seed = 0.0;
uniform int f_fbm_wave_count = 4;
uniform float f_fbm_frequency = 1.0;
uniform float f_fbm_frequency_mult = 2.0;
uniform float f_fbm_amplitude = 0.5;
uniform float f_fbm_amplitude_mult = 0.5;
uniform float f_fbm_initial_speed = 1.0;
uniform float f_fbm_speed_ramp = 1.0;
uniform float f_fbm_drag = 0.0;
uniform float f_fbm_height = 1.0;
uniform float f_fbm_max_peak = 1.0;
uniform float f_fbm_peak_offset = 0.0;

group_uniforms Rendering;
uniform vec3 albedo_color : source_color = vec3(0.0, 0.2, 0.8);
uniform vec3 tip_color : source_color = vec3(1.0);
uniform float tip_attenuation = 1.0;

uniform vec3 fresnel_color : source_color = vec3(1.0);
uniform float fresnel_strength = 1.0;
uniform float fresnel_bias = 0.0;
uniform float fresnel_shininess = 5.0;
uniform float fresnel_normal_strength = 1.0;

uniform float normal_strength = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

uniform samplerCube environment_map;
uniform bool use_environment_map = false;


// --- HELPER FUNCTIONS ---

vec2 get_direction(vec3 v, Wave w) {
	if (circular_waves) {
		vec2 p = vec2(v.x, v.z);
		return normalize(p - w.origin);
	} else {
		return w.direction;
	}
}

float get_wave_coord(vec3 v, vec2 d, Wave w) {
	if (circular_waves) {
		vec2 p = vec2(v.x, v.z);
		return length(p - w.origin);
	}
	return v.x * d.x + v.z * d.y;
}

float get_time(Wave w) {
	if (circular_waves) {
		return -TIME * w.phase;
	}
	return TIME * w.phase;
}

// Sine
float sine_wave(vec3 v, Wave w) {
	vec2 d = get_direction(v, w);
	float xz = get_wave_coord(v, d, w);
	float t = get_time(w);
	return w.amplitude * sin(xz * w.frequency + t);
}

vec3 sine_normal(vec3 v, Wave w) {
	vec2 d = get_direction(v, w);
	float xz = get_wave_coord(v, d, w);
	float t = get_time(w);
	vec2 n = w.frequency * w.amplitude * d * cos(xz * w.frequency + t);
	return vec3(n.x, n.y, 0.0);
}

// Steep Sine
float steep_sine(vec3 v, Wave w) {
	vec2 d = get_direction(v, w);
	float xz = get_wave_coord(v, d, w);
	float t = get_time(w);
	return 2.0 * w.amplitude * pow((sin(xz * w.frequency + t) + 1.0) / 2.0, w.steepness);
}

vec3 steep_sine_normal(vec3 v, Wave w) {
	vec2 d = get_direction(v, w);
	float xz = get_wave_coord(v, d, w);
	float t = get_time(w);
	float h = pow((sin(xz * w.frequency + t) + 1.0) / 2.0, max(1.0, w.steepness - 1.0));
	vec2 n = d * w.steepness * w.frequency * w.amplitude * h * cos(xz * w.frequency + t);
	return vec3(n.x, n.y, 0.0);
}

// Gerstner
vec3 gerstner(vec3 v, Wave w) {
	vec2 d = get_direction(v, w);
	float xz = get_wave_coord(v, d, w);
	float t = get_time(w);

	vec3 g = vec3(0.0);
	g.x = w.steepness * w.amplitude * d.x * cos(w.frequency * xz + t);
	g.z = w.steepness * w.amplitude * d.y * cos(w.frequency * xz + t);
	g.y = w.amplitude * sin(w.frequency * xz + t);
	return g;
}

vec3 gerstner_normal(vec3 v, Wave w) {
	vec2 d = get_direction(v, w);
	float xz = get_wave_coord(v, d, w);
	float t = get_time(w);

	vec3 n = vec3(0.0);
	float wa = w.frequency * w.amplitude;
	float s = sin(w.frequency * xz + t);
	float c = cos(w.frequency * xz + t);

	n.x = d.x * wa * c;
	n.z = d.y * wa * c;
	n.y = w.steepness * wa * s;
	return n;
}

// Calculations
vec3 calculate_offset(vec3 v, Wave w) {
	if (wave_type == 0) return vec3(0.0, sine_wave(v, w), 0.0);
	if (wave_type == 1) return vec3(0.0, steep_sine(v, w), 0.0);
	if (wave_type == 2) return gerstner(v, w);
	return vec3(0.0);
}

vec3 calculate_normal(vec3 v, Wave w) {
	if (wave_type == 0) return sine_normal(v, w);
	if (wave_type == 1) return steep_sine_normal(v, w);
	if (wave_type == 2) return gerstner_normal(v, w);
	return vec3(0.0);
}

// FBM Logic
vec3 vertex_fbm(vec3 v) {
	float f = v_fbm_frequency;
	float a = v_fbm_amplitude;
	float speed = v_fbm_initial_speed;
	float seed = v_fbm_seed;
	vec3 p = v;
	float amplitude_sum = 0.0;
	float h = 0.0;
	vec2 n = vec2(0.0);

	for (int i = 0; i < v_fbm_wave_count; ++i) {
		vec2 d = normalize(vec2(cos(seed), sin(seed)));
		float x = dot(d, p.xz) * f + TIME * speed;
		float wave = a * exp(v_fbm_max_peak * sin(x) - v_fbm_peak_offset);
		float dx = v_fbm_max_peak * wave * cos(x);

		h += wave;
		p.xz += d * -dx * a * v_fbm_drag;

		amplitude_sum += a;
		f *= v_fbm_frequency_mult;
		a *= v_fbm_amplitude_mult;
		speed *= v_fbm_speed_ramp;
		seed += 123.45; // Arbitrary iterator
	}

	vec3 output = vec3(h, n.x, n.y) / amplitude_sum;
	output.x *= v_fbm_height;
	return output;
}

vec3 fragment_fbm(vec3 v) {
	float f = f_fbm_frequency;
	float a = f_fbm_amplitude;
	float speed = f_fbm_initial_speed;
	float seed = f_fbm_seed;
	vec3 p = v;

	float h = 0.0;
	vec2 n = vec2(0.0);
	float amplitude_sum = 0.0;

	for (int i = 0; i < f_fbm_wave_count; ++i) {
		vec2 d = normalize(vec2(cos(seed), sin(seed)));
		float x = dot(d, p.xz) * f + TIME * speed;
		float wave = a * exp(f_fbm_max_peak * sin(x) - f_fbm_peak_offset);
		vec2 dw = f * d * (f_fbm_max_peak * wave * cos(x));

		h += wave;
		p.xz += -dw * a * f_fbm_drag;
		n += dw;

		amplitude_sum += a;
		f *= f_fbm_frequency_mult;
		a *= f_fbm_amplitude_mult;
		speed *= f_fbm_speed_ramp;
		seed += 123.45;
	}

	vec3 output = vec3(h, n.x, n.y) / amplitude_sum;
	output.x *= f_fbm_height;
	return output;
}

// --- VARYINGS ---
varying float height_val;
varying vec3 world_pos;

// --- SHADER STAGES ---

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Prepare Wave Array (Simulated for this demo)
	// In a real project, you might pass these via specific uniform arrays
	Wave waves[MAX_WAVES];
	// Initialize Wave 0 from uniforms
	waves[0] = Wave(normalize(wave_0_direction), vec2(0.0), wave_0_frequency, wave_0_amplitude, wave_0_speed, wave_0_steepness);

	if (use_vertex_displacement) {
		vec3 h = vec3(0.0);
		vec3 n = vec3(0.0);

		if (use_fbm) {
			vec3 fbm = vertex_fbm(world_pos);
			h.y = fbm.x;
			n.xy = fbm.yz;
		} else {
			for (int i = 0; i < wave_count; ++i) {
				// Prevent out of bounds if wave_count > 1 but we only init 1
				if(i >= 1) break; 
				
				h += calculate_offset(world_pos, waves[i]);
				if (wave_type != 2 && !normals_in_pixel_shader) {
					n += calculate_normal(world_pos, waves[i]);
				}
			}
		}

		VERTEX += h;
		height_val = h.y;
		
		// Recalculate World Pos for Fragment
		world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

		if (!normals_in_pixel_shader) {
			vec3 final_norm;
			if (wave_type == 2) {
				// Gerstner Normal Accumulation
				for (int i = 0; i < wave_count; ++i) {
					if(i >= 1) break;
					n += calculate_normal(world_pos, waves[i]);
				}
				final_norm = normalize(vec3(-n.x, 1.0 - n.y, -n.z));
			} else {
				final_norm = normalize(vec3(-n.x, 1.0, -n.y));
			}
			NORMAL = normalize((MODEL_MATRIX * vec4(final_norm, 0.0)).xyz);
		}
	}
}

void fragment() {
	// Reconstruct Wave Array (needed in fragment if calculating normals per pixel)
	Wave waves[MAX_WAVES];
	waves[0] = Wave(normalize(wave_0_direction), vec2(0.0), wave_0_frequency, wave_0_amplitude, wave_0_speed, wave_0_steepness);

	vec3 norm_calc = vec3(0.0);
	float h_calc = height_val;

	if (normals_in_pixel_shader) {
		if (use_fbm) {
			vec3 fbm = fragment_fbm(world_pos);
			h_calc = fbm.x;
			norm_calc.xy = fbm.yz;
		} else {
			for (int i = 0; i < wave_count; ++i) {
				if(i >= 1) break;
				norm_calc += calculate_normal(world_pos, waves[i]);
			}
		}
		
		vec3 final_n;
		if (wave_type == 2) {
			final_n = normalize(vec3(-norm_calc.x, 1.0 - norm_calc.y, -norm_calc.z));
		} else {
			final_n = normalize(vec3(-norm_calc.x, 1.0, -norm_calc.y));
		}
		// Convert to view space for Godot NORMAL
		NORMAL = mat3(VIEW_MATRIX) * normalize((MODEL_MATRIX * vec4(final_n, 0.0)).xyz);
	}

	// Apply Normal Strength (Partial Derivative approximation adjustment)
	// Godot handles NORMAL maps via property, but since we calculated geometric normal above:
	// We can cheat strength by blending with up vector in tangent space, 
	// but here we just pass the calculated normal. 
	// If you want "Normal Strength", scaling the XZ of the calculated normal before normalization works.

	// PBR Mapping
	ALBEDO = albedo_color;
	
	// Tip Color
	float tip_mix = pow(clamp(h_calc, 0.0, 1.0), tip_attenuation);
	ALBEDO = mix(ALBEDO, tip_color, tip_mix);

	// Fresnel Calculation (Schlick)
	// Godot has built-in Fresnel, but for custom control:
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
	vec3 n_world = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// Adjust normal for fresnel effect specifically
	vec3 fresnel_norm = n_world;
	fresnel_norm.xz *= fresnel_normal_strength;
	fresnel_norm = normalize(fresnel_norm);

	float base = 1.0 - dot(view_dir, fresnel_norm);
	float exponential = pow(max(base, 0.0), fresnel_shininess);
	float R = exponential + fresnel_bias * (1.0 - exponential);
	R *= fresnel_strength;
	
	vec3 final_fresnel = fresnel_color * R;

	if (use_environment_map) {
		vec3 reflected_dir = reflect(-view_dir, n_world);
		vec3 sky_col = texture(environment_map, reflected_dir).rgb;
		// Sun approximation usually requires a specific light direction. 
		// In Godot, you rely on the Sky resource or DirectionalLight3D.
		// We add the Sky reflection to Emission to simulate the custom enviro reflection.
		final_fresnel += sky_col * R;
	}

	EMISSION = final_fresnel;
	ROUGHNESS = roughness;
	METALLIC = metallic;
}