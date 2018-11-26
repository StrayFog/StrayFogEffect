/*

*/
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

float3 CalcGerstnerWaveOffset(half3 posVtx, half3 scaleVtx, half4 steepness, half4 amplitude, half4 frequency, half4 speed, half4 directionAB, half4 directionCD)
{
	float3 sum = float3(0, 0, 0);
	int numWaves = 4;

	float4 dirx = float4(directionAB.x, directionAB.z, directionCD.x, directionCD.z);
	float4 dirz = float4(directionAB.y, directionAB.w, directionCD.y, directionCD.w);


	//[unroll]
	for (int i = 0; i < numWaves; i++)
	{
		float wi = frequency[i];
		float Qi = steepness[i] / (amplitude[i] * wi * numWaves);
		float phi = speed[i] * wi;

		float2 waveDir = float2(dirx[i], dirz[i]);

		float rad = wi * dot(waveDir, posVtx.xz) + phi * _Time.y;
		sum.y += sin(rad) * amplitude[i];
		sum.xz += cos(rad) * amplitude[i] * Qi * waveDir;
	}
	return sum;
}