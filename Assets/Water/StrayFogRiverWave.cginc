#ifndef STRAYFOGRIVERWAVE_CG_INCLUDED
#define STRAYFOGRIVERWAVE_CG_INCLUDED

#define MOD2 float2(4.438975,3.972973);

float Hash(float p)
{
	// https://www.shadertoy.com/view/4djSRW - Dave Hoskins
	float2 mod2 = MOD2;
	float2 p2 = frac(float2(p, p) * mod2);
	p2 += dot(p2.yx, p2.xy + 19.19);
	return frac(p2.x * p2.y);
	//return fract(sin(n)*43758.5453);
}

float SmoothNoise(in float2 o)
{
	float2 p = floor(o);
	float2 f = frac(o);

	float n = p.x + p.y*57.0;

	float a = Hash(n + 0.0);
	float b = Hash(n + 1.0);
	float c = Hash(n + 57.0);
	float d = Hash(n + 58.0);

	float2 f2 = f * f;
	float2 f3 = f2 * f;

	float2 t = 3.0 * f2 - 2.0 * f3;

	float u = t.x;
	float v = t.y;

	float res = a + (b - a)*u + (c - a)*v + (a - b + d - c)*u*v;

	return res;
}

float3 Tonemap(float3 x)
{
	float a = 0.010;
	float b = 0.132;
	float c = 0.010;
	float d = 0.163;
	float e = 0.101;

	return (x * (a * x + b)) / (x * (c * x + d) + e);
}
#endif