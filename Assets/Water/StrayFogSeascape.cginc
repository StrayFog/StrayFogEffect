#define NUM_STEPS int(8)
#define PI float(3.141592)
#define EPSILON float(1e-3)
#define EPSILON_NRM (0.1 / _ScreenParams.x)

// sea
#define ITER_GEOMETRY int(3);
#define ITER_FRAGMENT int(5);
#define SEA_HEIGHT float(0.6);
#define SEA_CHOPPY float(4.0);
#define SEA_SPEED float(0.8);
#define SEA_FREQ float(0.16);
#define SEA_BASE float3(0.1, 0.19, 0.22);
#define SEA_WATER_COLOR float3(0.8, 0.9, 0.6);
#define octave_m float2x2(1.6, 1.2, -1.2, 1.6);

float SEA_TIME()
{
	return 1.0 + _Time.y * SEA_SPEED;
}

// math
float3x3 fromEuler(float3 ang) {
	float2 a1 = float2(sin(ang.x), cos(ang.x));
	float2 a2 = float2(sin(ang.y), cos(ang.y));
	float2 a3 = float2(sin(ang.z), cos(ang.z));
	float3x3 m;
	m[0] = float3(a1.y*a3.y + a1.x*a2.x*a3.x, a1.y*a2.x*a3.x + a3.y*a1.x, -a2.y*a3.x);
	m[1] = float3(-a2.y*a1.x, a1.y*a2.y, a2.x);
	m[2] = float3(a3.y*a1.x*a2.x + a1.y*a3.x, a1.x*a3.x - a1.y*a3.y*a2.x, a2.y*a3.y);
	return m;
}
float hash(float2 p) {
	float h = dot(p, float2(127.1, 311.7));
	return frac(sin(h)*43758.5453123);
}
float noise(in float2 p) {
	float2 i = floor(p);
	float2 f = frac(p);
	float2 u = f * f*(3.0 - 2.0*f);
	return -1.0 + 2.0*lerp(lerp(hash(i + float2(0.0, 0.0)),
		hash(i + float2(1.0, 0.0)), u.x),
		lerp(hash(i + float2(0.0, 1.0)),
			hash(i + float2(1.0, 1.0)), u.x), u.y);
}

// lighting
float diffuse(float3 n, float3 l, float p) {
	return pow(dot(n, l) * 0.4 + 0.6, p);
}

float specular(float3 n, float3 l, float3 e, float s) {
	float nrm = (s + 8.0) / (PI * 8.0);
	return pow(max(dot(reflect(e, n), l), 0.0), s) * nrm;
}

// sky
float3 getSkyColor(float3 e) {
	e.y = max(e.y, 0.0);
	return float3(pow(1.0 - e.y, 2.0), 1.0 - e.y, 0.6 + (1.0 - e.y)*0.4);
}

// sea
float sea_octave(float2 uv, float choppy) {
	uv += noise(uv);
	float2 wv = 1.0 - abs(sin(uv));
	float2 swv = abs(cos(uv));
	wv = lerp(wv, swv, wv);
	return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy);
}

float map(float3 p) {
	float freq = SEA_FREQ;
	float amp = SEA_HEIGHT;
	float choppy = SEA_CHOPPY;
	float2 uv = p.xz; uv.x *= 0.75;

	float d, h = 0.0;
	int index = ITER_GEOMETRY;
	float2x2 om = octave_m;
	for (int i = 0; i < index; i++) {
		d = sea_octave((uv + SEA_TIME())*freq, choppy);
		d += sea_octave((uv - SEA_TIME())*freq, choppy);
		h += d * amp;
		uv = mul(uv, om);
		freq *= 1.9; amp *= 0.22;
		choppy = lerp(choppy, 1.0, 0.2);
	}
	return p.y - h;
}

float map_detailed(float3 p) {
	float freq = SEA_FREQ;
	float amp = SEA_HEIGHT;
	float choppy = SEA_CHOPPY;
	float2 uv = p.xz; uv.x *= 0.75;

	float d, h = 0.0;
	int index = ITER_FRAGMENT;
	float2x2 om = octave_m;	
	for (int i = 0; i < index; i++) {
		d = sea_octave((uv + SEA_TIME())*freq, choppy);
		d += sea_octave((uv - SEA_TIME())*freq, choppy);
		h += d * amp;
		uv = mul(uv, om);
		freq *= 1.9; amp *= 0.22;
		choppy = lerp(choppy, 1.0, 0.2);
	}
	return p.y - h;
}

float3 getSeaColor(float3 p, float3 n, float3 l, float3 eye, float3 dist) {
	float fresnel = clamp(1.0 - dot(n, -eye), 0.0, 1.0);
	fresnel = pow(fresnel, 3.0) * 0.65;

	float3 reflected = getSkyColor(reflect(eye, n));
	float3 sb = SEA_BASE;
	float3 swc = SEA_WATER_COLOR;
	float3 refracted = sb + diffuse(n, l, 80.0) * swc * 0.12;

	float3 color = lerp(refracted, reflected, fresnel);

	float atten = max(1.0 - dot(dist, dist) * 0.001, 0.0);
	float sh = SEA_HEIGHT;
	color += swc * (p.y - sh) * 0.18 * atten;

	float sc = specular(n, l, eye, 60.0);
	color += float3(sc,sc,sc);

	return color;
}

// tracing
float3 getNormal(float3 p, float eps) {
	float3 n;
	n.y = map_detailed(p);
	n.x = map_detailed(float3(p.x + eps, p.y, p.z)) - n.y;
	n.z = map_detailed(float3(p.x, p.y, p.z + eps)) - n.y;
	n.y = eps;
	return normalize(n);
}

float heightMapTracing(float3 ori, float3 dir, out float3 p) {
	float tm = 0.0;
	float tx = 1000.0;
	float hx = map(ori + dir * tx);
	if (hx > 0.0) return tx;
	float hm = map(ori + dir * tm);
	float tmid = 0.0;
	int steps = NUM_STEPS;
	for (int i = 0; i < steps; i++) {
		tmid = lerp(tm, tx, hm / (hm - hx));
		p = ori + dir * tmid;
		float hmid = map(p);
		if (hmid < 0.0) {
			tx = tmid;
			hx = hmid;
		}
		else {
			tm = tmid;
			hm = hmid;
		}
	}
	return tmid;
}

/*
float2 uv = IN.texcoord.xy - 1.5;
			float time = _Time.x * 0.3;

			// ray
			float3 ang = float3(sin(time*3.0)*0.1, sin(time)*0.2 + 0.3, time);
			float3 ori = float3(0.0, 3.5, time*5.0);
			float3 dir = normalize(float3(uv.xy, -2.0)); dir.z += length(uv) * 0.15;
			dir = mul(normalize(dir) , fromEuler(ang));

			// tracing
			float3 p;
			heightMapTracing(ori, dir, p);
			float3 dist = p - ori;
			float3 n = getNormal(p, dot(dist, dist) * EPSILON_NRM);
			float3 light = normalize(float3(0.0, 1.0, 0.8));

			// color
			float3 color = lerp(
				getSkyColor(dir),
				getSeaColor(p, n, light, dir, dist),
				pow(smoothstep(0.0, -0.05, dir.y), 0.3));

			// post
			color.x = pow(color.x, 0.75);
			color.y = pow(color.y, 0.75);
			color.z = pow(color.z, 0.75);

			float4 fragColor = float4(color.x, color.y, color.z, 1.0);
			o.Albedo = fragColor;
*/