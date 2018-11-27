
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