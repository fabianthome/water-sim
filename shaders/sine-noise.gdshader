shader_type spatial;

// Wave Movements Params
uniform float amplitude = 0.1; // a
uniform float frequency = 2.0; // w
uniform float speed = 2.0; // p

// Coloring Params
uniform vec3 albedo : source_color;
uniform vec3 albedo2 : source_color;
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness: hint_range(0.0, 1.0) = 0.02;

uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;
uniform vec2 wave_direction = vec2(2.0,0.0);
uniform vec2 wave_direction2 = vec2(0.0,1.0);
uniform float time_scale: hint_range(0.0, 0.2, 0.005) = 0.025;

varying vec3 world_pos;

float fresnel(float amount, vec3 normal, vec3 view)
{
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void vertex() {
	// Called for every vertex the material is visible on.
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Calculate wave height based on X position and time
	float wave = amplitude * sin(VERTEX.x * frequency + TIME * speed);
	
	// Apply to the Y coordinate
	VERTEX.y += wave;
}

void fragment() {
	// Called for every pixel the material is visible on.
    vec2 time = (TIME * wave_direction) * time_scale; // Movement rate of first wave
    vec2 time2 = (TIME * wave_direction2) * time_scale; // Movement rate of second wave
    vec3 normal_blend = mix(texture(texture_normal, world_pos.xz + time).rgb, texture(texture_normal2, world_pos.xz + time2).rgb, 0.5);

    float fresnel = fresnel(5.0, NORMAL, VIEW);
    vec3 surface_color = mix(albedo, albedo2, fresnel); // Interpolate albedo values by fresnel
    
    ALBEDO = surface_color;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = 0.8;
    NORMAL_MAP = normal_blend;
    
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
