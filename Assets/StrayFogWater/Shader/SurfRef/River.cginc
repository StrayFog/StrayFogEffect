#define PI 3.14159265359
#define PI2 6.28318530718
#define Deg2Radius PI/180.
#define Radius2Deg 180./PI

//向量旋转
float2 RotationVector(float2 vec, float angle)
{
	float radZ = radians(-angle);
	float sinZ, cosZ;
	sincos(radZ, sinZ, cosZ);
	return normalize(float2(vec.x * cosZ - vec.y * sinZ,
		vec.x * sinZ + vec.y * cosZ));
}

//Tiled坐标RTS转换
float2 TiledRTS(float2 vec, float rotation, float2 offset, float scale,bool isClamp)
{
	half2 x0y0 = floor(vec * scale) / scale;
	half2 center = x0y0 + 0.5 / scale;
	half2 xy = (vec - x0y0) * scale;
	float2 result = vec;
	if (isClamp)
	{
		result = RotationVector(xy + offset - 0.5, rotation) + 0.5;
	}
	else
	{
		result = RotationVector(vec + offset - center, rotation) + center;
	}
	return result;
}

float TimeNoiseFBM(sampler2D t2d, float2 p, float t)
{
	float2 f = 0.0;
	float s = 0.5;
	float sum = 0;
	for (int i = 0; i < 5; i++) {
		p += t;//位置添加时间偏移
		t *= 1.5;//每一层时间偏移不同 等到不同分层不同移速的效果
		f += s * tex2D(t2d, p / 256).x; p = mul(float2x2(0.8, -0.6, 0.6, 0.8), p)*2.02;
		sum += s; s *= 0.6;
	}
	return f / sum;
}

#define iTime _Time.x

float hash(float n)
{
	return frac(sin(n)*43758.5453);
}

float fastNoise(in float2 x)
{
	float2 p = floor(x);
	float2 f = frac(x);
	f = f * f*(3.0 - 2.0*f);
	float n = p.x + p.y*57.0;
	return lerp(lerp(hash(n + 0.0), hash(n + 1.0), f.x),
		lerp(hash(n + 57.0), hash(n + 58.0), f.x), f.y);
}

float2 map(float2 p, in float offset)
{
	p.x += 0.1*sin(iTime + 2.0*p.y);
	p.y += 0.1*sin(iTime + 2.0*p.x);

	float a = fastNoise(p*1.5 + sin(0.1*iTime))*6.2831;
	a -= offset;
	return float2(cos(a), sin(a));
}


/*
#define DEF_MOD2 float2(4.438975,3.972973)
#define DEF_FMBSTEPS float(6);
#define  DEF_FMBWATERSTEPS int(4);

float Hash(float p)
{
	// https://www.shadertoy.com/view/4djSRW - Dave Hoskins	
	float2 p2 = frac(float2(p,p) * DEF_MOD2);
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

float FBM(float2 p, float ps) {
	float f = 0.0;
	float tot = 0.0;
	float a = 1.0;
	float fmbStep = DEF_FMBSTEPS;
	for (int i = 0; i < fmbStep; i++)
	{
		f += SmoothNoise(p) * a;
		p *= 2.0;
		tot += a;
		a *= ps;
	}
	return f / tot;
}

float FBM_Simple(float2 p, float ps) {
	float f = 0.0;
	float tot = 0.0;
	float a = 1.0;
	for (int i = 0; i < 3; i++)
	{
		f += SmoothNoise(p) * a;
		p *= 2.0;
		tot += a;
		a *= ps;
	}
	return f / tot;
}

float3 SmoothNoise_DXY(in float2 o)
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
	float2 dt = 6.0 * f - 6.0 * f2;

	float u = t.x;
	float v = t.y;
	float du = dt.x;
	float dv = dt.y;

	float res = a + (b - a)*u + (c - a)*v + (a - b + d - c)*u*v;

	float dx = (b - a)*du + (a - b + d - c)*du*v;
	float dy = (c - a)*dv + (a - b + d - c)*u*dv;

	return float3(dx, dy, res);
}

float3 FBM_DXY(float2 p, float2 flow, float ps, float df) {
	float3 f = 0;
	float tot = 0.0;
	float a = 1.0;
	//flow *= 0.6;
	int k_fmbWaterSteps = DEF_FMBWATERSTEPS;
	for (int i = 0; i < k_fmbWaterSteps; i++)
	{
		p += flow;
		flow *= -0.75; // modify flow for each octave - negating this is fun
		float3 v = SmoothNoise_DXY(p);
		f += v * a;
		p += v.xy * df;
		p *= 2.0;
		tot += a;
		a *= ps;
	}
	return f / tot;
}

float GetRiverMeander(in float x)
{
	return sin(x * 0.3) * 1.5;
}

float GetRiverMeanderDx(in float x)
{
	return cos(x * 0.3) * 1.5 * 0.3;
}

float GetRiverBedOffset(in float3 vPos)
{
	float fRiverBedDepth = 0.3 + (0.5 + 0.5 * sin(vPos.x * 0.001 + 3.0)) * 0.4;
	float fRiverBedWidth = 2.0 + cos(vPos.x * 0.1) * 1.0;;

	float fRiverBedAmount = smoothstep(fRiverBedWidth, fRiverBedWidth * 0.5, abs(vPos.z - GetRiverMeander(vPos.x)));

	return fRiverBedAmount * fRiverBedDepth;
}

float GetTerrainHeight(in float3 vPos)
{
	float fbm = FBM(vPos.xz * float2(0.5, 1.0), 0.5);
	float fTerrainHeight = fbm * fbm;

	fTerrainHeight -= GetRiverBedOffset(vPos);

	return fTerrainHeight;
}

float GetTerrainHeightSimple(in float3 vPos)
{
	float fbm = FBM_Simple(vPos.xz * float2(0.5, 1.0), 0.5);
	float fTerrainHeight = fbm * fbm;

	fTerrainHeight -= GetRiverBedOffset(vPos);

	return fTerrainHeight;
}

float GetSceneDistance(in float3 vPos)
{
	return vPos.y - GetTerrainHeight(vPos);
}

float GetFlowDistance(in float2 vPos)
{
	return -GetTerrainHeightSimple(float3(vPos.x, 0.0, vPos.y));
}

float2 GetBaseFlow(in float2 vPos)
{
	return float2(1.0, GetRiverMeanderDx(vPos.x));
}

float2 GetGradient(in float2 vPos)
{
	float2 vDelta = float2(0.01, 0.00);
	float dx = GetFlowDistance(vPos + vDelta.xy) - GetFlowDistance(vPos - vDelta.xy);
	float dy = GetFlowDistance(vPos + vDelta.yx) - GetFlowDistance(vPos - vDelta.yx);
	return float2(dx, dy);
}

float3 GetFlowRate(in float2 vPos)
{
	float2 vBaseFlow = GetBaseFlow(vPos);

	float2 vFlow = vBaseFlow;

	float fFoam = 0.0;

	float fDepth = -GetTerrainHeightSimple(float3(vPos.x, 0.0, vPos.y));
	float fDist = GetFlowDistance(vPos);
	float2 vGradient = GetGradient(vPos);

	vFlow += -vGradient * 40.0 / (1.0 + fDist * 1.5);
	vFlow *= 1.0 / (1.0 + fDist * 0.5);

#if 1
	float fBehindObstacle = 0.5 - dot(normalize(vGradient), -normalize(vFlow)) * 0.5;
	float fSlowDist = clamp(fDepth * 5.0, 0.0, 1.0);
	fSlowDist = lerp(fSlowDist * 0.9 + 0.1, 1.0, fBehindObstacle * 0.9);
	//vFlow += vGradient * 10.0 * (1.0 - fSlowDist);
	fSlowDist = 0.5 + fSlowDist * 0.5;
	vFlow *= fSlowDist;
#endif    

	float fFoamScale1 = 0.5;
	float fFoamCutoff = 0.4;
	float fFoamScale2 = 0.35;

	fFoam = abs(length(vFlow)) * fFoamScale1;// - length( vBaseFlow ));
	fFoam += clamp(fFoam - fFoamCutoff, 0.0, 1.0);
	//fFoam = fFoam* fFoam;
	fFoam = 1.0 - pow(fDist, fFoam * fFoamScale2);
	//fFoam = fFoam / fDist;
	return float3(vFlow * 0.6, fFoam);
}

float4 SampleWaterNormal(float2 vUV, float2 vFlowOffset, float fMag, float fFoam)
{
	float2 vFilterWidth = max(abs(ddx(vUV)), abs(ddy(vUV)));
	float fFilterWidth = max(vFilterWidth.x, vFilterWidth.y);

	float fScale = (1.0 / (1.0 + fFilterWidth * fFilterWidth * 2000.0));
	float fGradientAscent = 0.25 + (fFoam * -1.5);
	float3 dxy = FBM_DXY(vUV * 20.0, vFlowOffset * 20.0, 0.75 + fFoam * 0.25, fGradientAscent);
	fScale *= max(0.25, 1.0 - fFoam * 5.0); // flatten normal in foam
	float3 vBlended = lerp(float3(0.0, 1.0, 0.0), normalize(float3(dxy.x, fMag, dxy.y)), fScale);
	return float4(normalize(vBlended), dxy.z * fScale);
}

float SampleWaterFoam(float2 vUV, float2 vFlowOffset, float fFoam)
{
	float f = FBM_DXY(vUV * 30.0, vFlowOffset * 50.0, 0.8, -0.5).z;
	float fAmount = 0.2;
	f = max(0.0, (f - fAmount) / fAmount);
	return pow(0.5, f);
}

float4 SampleFlowingNormal(in float2 vUV, in float2 vFlowRate, in float fFoam, in float time, out float fOutFoamTex)
{
	float fMag = 2.5 / (1.0 + dot(vFlowRate, vFlowRate) * 5.0);
	float t0 = frac(time);
	float t1 = frac(time + 0.5);

	float o0 = t0 - 0.5;
	float o1 = t1 - 0.5;

	float4 sample0 = SampleWaterNormal(vUV, vFlowRate * o0, fMag, fFoam);
	float4 sample1 = SampleWaterNormal(vUV, vFlowRate * o1, fMag, fFoam);

	float weight = abs(t0 - 0.5) * 2.0;
	//weight = smoothstep( 0.0, 1.0, weight );

	float foam0 = SampleWaterFoam(vUV, vFlowRate * o0 * 0.25, fFoam);
	float foam1 = SampleWaterFoam(vUV, vFlowRate * o1 * 0.25, fFoam);

	float4 result = lerp(sample0, sample1, weight);
	result.xyz = normalize(result.xyz);

	fOutFoamTex = lerp(foam0, foam1, weight);

	return result;
}

float3 ApplyVignetting(in float2 vUV, in float3 vInput)
{
	float2 vOffset = (vUV - 0.5) * sqrt(2.0);

	float fDist = dot(vOffset, vOffset);

	float kStrength = 0.8;

	float fShade = lerp(1.0, 1.0 - kStrength, fDist);

	return vInput * fShade;
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

float tri(in float x) { return abs(frac(x) - .5); }

float3 tri3(in float3 p) { return float3(tri(p.z + tri(p.y)), tri(p.z + tri(p.x)), tri(p.y + tri(p.x))); }

float triNoise(in float3 p)
{
	float z = 1.4;
	float rz = 0.;
	float3 bp = p;
	for (float i = 0.; i <= 4.; i++)
	{
		float3 dg = tri3(bp*2.);
		p += dg;

		bp *= 1.8;
		z *= 1.5;
		p *= 1.2;

		rz += (tri(p.z + tri(p.x + tri(p.y)))) / z;
		bp += 0.14;
	}
	return rz;
}

float GIV(float dotNV, float k)
{
	return 1.0 / ((dotNV + 0.0001) * (1.0 - k) + k);
}

float3 GetFresnel(float3 vView, float3 vNormal, float3 vR0, float fGloss)
{
	float NdotV = max(0.0, dot(vView, vNormal));

	return vR0 + (1 - vR0) * pow(1.0 - NdotV, 5.0) * pow(fGloss, 20.0);
}

float3 GetWaterExtinction(float dist)
{
	float fOpticalDepth = dist * 6.0;

	float3 vExtinctCol = 1.0 - float3(0.5, 0.4, 0.1);
	float3 vExtinction = exp2(-fOpticalDepth * vExtinctCol);

	return vExtinction;
}
*/

//float snoise(float3 uv, float res)
//{
//	float3 s = float3(1e0, 1e2, 1e3);
//
//	uv *= res;
//
//	float3 uv0 = floor(fmod(uv, res))*s;
//	float3 uv1 = floor(fmod(uv + float3(1,1,1), res))*s;
//
//	float3 f = frac(uv); f = f * f*(3.0 - 2.0*f);
//
//	float4 v = float4(uv0.x + uv0.y + uv0.z, uv1.x + uv0.y + uv0.z,
//		uv0.x + uv1.y + uv0.z, uv1.x + uv1.y + uv0.z);
//
//	float4 r = frac(sin(v*1e-1)*1e3);
//	float r0 = lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y);
//
//	r = frac(sin((v + uv1.z - uv0.z)*1e-1)*1e3);
//	float r1 = lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y);
//
//	return lerp(r0, r1, f.z)*2. - 1.;
//}

//void noiseFireSurf(Input IN, inout SurfaceOutputStandardSpecular o) {
//	uv_WaterNormal = 0.5 - uv_WaterNormal;
//	float color = 3.0 - (3.*length(2.* uv_WaterNormal));
//
//	float3 coord = float3(atan(uv_WaterNormal.y / uv_WaterNormal.x) / 6.2832 + .5, length(uv_WaterNormal)*.4, .5);
//
//	for (int i = 1; i <= 7; i++)
//	{
//		float power = pow(2.0, float(i));
//		color += (1.5 / power) * snoise(coord + float3(0., -iTime * .05, iTime*.01), power*16.);
//	}
//	o.Emission = float3(color, pow(max(color, 0.), 2.)*0.4, pow(max(color, 0.), 3.)*0.15);
//
//	o.Specular = _Specular;
//	o.Smoothness = _Smoothness;
//	o.Occlusion = _Occlusion;
//	o.Alpha = 1;
//}


/*
half3 GerstnerWave(half3 posVtx,half3 scaleVtx,half4 steepness, half4 amp, half4 freq,
	half4 speed, half4 dirAB, half4 dirCD) {

	half3 offsets;

	half4 AB = steepness.xxyy * amp.xxyy * dirAB.xyzw;
	half4 CD = steepness.zzww * amp.zzww * dirCD.xyzw;

	half4 dotABCD = freq.xyzw * half4(dot(dirAB.xy, posVtx.xz), dot(dirAB.zw, posVtx.xz), dot(dirCD.xy, posVtx.xz), dot(dirCD.zw, posVtx.xz));
	half4 TIME = _Time.yyyy * speed;

	half4 COS = cos(dotABCD + TIME);
	half4 SIN = sin(dotABCD + TIME);

	offsets.x = dot(COS, half4(AB.xz, CD.xz));
	offsets.z = dot(COS, half4(AB.yw, CD.yw));
	offsets.y = dot(SIN, amp);

	offsets.xyz *= scaleVtx;

	return offsets;
}

half3 GerstnerNormal (half3 posVtx,half3 scaleVtx, half4 steepness, half4 amp, half4 freq, half4 speed, half4 dirAB, half4 dirCD) {
	half3 nrml = half3(0,2.0,0);

	// frequency might be anything... and easily goes crazy
	half4 AB = freq.xxyy  * amp.xxyy * dirAB.xyzw;
	half4 CD = freq.zzww  * amp.zzww * dirCD.xyzw;

//    half4 AB = steepness.xxyy * amp.xxyy * dirAB.xyzw;
//    half4 CD = steepness.zzww * amp.zzww * dirCD.xyzw;

	half4 dotABCD = freq.xyzw * half4(dot(dirAB.xy, posVtx.xz), dot(dirAB.zw, posVtx.xz), dot(dirCD.xy, posVtx.xz), dot(dirCD.zw, posVtx.xz));
	half4 TIME = _Time.yyyy * speed;

	half4 COS = cos (dotABCD + TIME);

	nrml.x -= dot(COS, half4(AB.xz, CD.xz)) ;
	nrml.z -= dot(COS, half4(AB.yw, CD.yw)) ;

	nrml.xz *= scaleVtx;
	nrml = normalize (nrml);

	return nrml;
}
*/