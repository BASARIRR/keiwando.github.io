precision highp float;

const float PI = 3.1415926;

uniform float force;
uniform float altitude;
uniform float azimuth;
uniform float movementDirection;
uniform float speed;
uniform float stiffness;
uniform float bristleLength; 

uniform float frameNum;

uniform sampler2D texture;

varying vec2 vTextureCoord;
varying float vScaleFactor;

// --------------------    Simplex NOISE    ------------------------- //

//
// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
// 

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

// --------------------    Color Transfer    ------------------------- //

float PHI = 1.61803398874989484820459 * 00000.1; // Golden Ratio
float PI_2  = 3.14159265358979323846264 * 00000.1; // PI
float SQ2 = 1.41421356237309504880169 * 10000.0; // Square Root of Two

float gold_noise(vec2 coordinate, float seed){
    
    return pow(fract((sin(dot(coordinate*(seed+PHI), vec2(PHI, PI_2))) + 1.0) * 0.5 * SQ2), 4.0);
    //return fract(sin(dot(coordinate*(seed+PHI), vec2(PHI, PI_2)))*SQ2);
}

float rand(vec2 co){
	//return snoise(co);
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

/*float rand(vec2 co){
    return fract(dot(co.xy * 0.001 , vec2(12.9898,78.233)) * 43758.5453);
}*/

float avg_noise(vec2 coord, float seed){
    
    float n1 = gold_noise(vec2(coord[0] - 1.0, coord[1] - 1.0), seed);
    float n2 = gold_noise(vec2(coord[0], coord[1] - 1.0), seed);
    float n3 = gold_noise(vec2(coord[0] + 1.0, coord[1] - 1.0), seed);
    float n4 = gold_noise(vec2(coord[0] - 1.0, coord[1]), seed);
    float n5 = gold_noise(vec2(coord[0], coord[1]), seed);
    float n6 = gold_noise(vec2(coord[0] + 1.0, coord[1]), seed);
    float n7 = gold_noise(vec2(coord[0] - 1.0, coord[1] + 1.0), seed);
    float n8 = gold_noise(vec2(coord[0], coord[1] + 1.0), seed);
    float n9 = gold_noise(vec2(coord[0] + 1.0, coord[1] + 1.0), seed);
    
    //return (n1 + n2 + n3 + n4 + n5 + n6 + n7 + n8 + n9) / 4.0;
    return (n1 + n2 + n3 + n4 + n5 + n6 + n7 + n8 + n9) / 8.0;
    //return (n2 + n4 + n5 + n6 + n8) / 5.0;
    //return n5;
}

float colorAmount(float frameNum) {

    float minAmount = 0.01;
    
    return max(1.0 - 0.8 * (1.0 / (1.0 + exp(-(frameNum / 100.0 - 4.0)))) - 0.00001 * frameNum, minAmount);
}

float baseOffset(vec2 coord, float frameNum) {

	float res = 128.0;
	//float res = 256.0 * rand(floor(coord * 20.0)) + 4.0;

	return 0.5 * (1.0 + sin(coord.x * res) * sin(coord.y * res) * sin(frameNum * 2.0 * PI / 300.0 + res));
}

float valueAtCenter(vec2 center, float frameNum) {

	highp float randFromCenter = rand(center);

    float frameNumFloor = floor(frameNum / 70.0) + randFromCenter * 20000.0;
    
    float periodDuration = 1000.0 * rand(center + frameNumFloor / (center * 1000.0)) + 500.0;
    
    float t = (frameNum / periodDuration) * 2.0 * PI; + randFromCenter * 50000.0;
    
    float ampl = rand(center + floor(t / (2.0 * PI)));

    float offset = 0.01 + colorAmount(frameNum) * 0.1;
    float noiseVal = ampl * sin(t) + offset;

    return noiseVal;
}

highp vec2 centerForCoord(vec2 coord, float res) {

    highp vec2 coordFloor = floor(coord * res);// + coordShift;// / res;
    highp vec2 center = (floor(coord * res) + 0.5);// - coordShift;

    return center;
}

float angleBetween(vec2 origin, vec2 point) {

	vec2 norm = normalize(point - origin);

	return sign(norm.y) * acos(dot(norm, vec2(1.0, 0.0)));

	//return atan2((point.y - origin.y) / (point.x - origin.x));
	//return acos(dot(origin, point));
}

vec2 nextCenter(vec2 center, float angle) {

	float cA = cos(angle);
	float sA = sin(angle);

	float x = cA > 0.0 ? floor(cA) : ceil(cA);
	float y = sA > 0.0 ? floor(sA) : ceil(sA);

	return center + vec2(x, y);
}

float distanceWeight(vec2 coord, vec2 center, float res) {

	float radius = 4.0;

	return (radius - min(radius, distance(coord * res, center) * 4.0));
}

/*float avgBetweenCenters(vec2 center, vec2 coord, float frameNum, float res) {

	float angle = angleBetween(center, coord * res);

	float dAngle = PI / 2.0;

	// Determine 3 surrounding center values and average them
	vec2 nextCenter1 = nextCenter(center, angle);
	vec2 nextCenter2 = nextCenter(center, angle + dAngle);
	vec2 nextCenter3 = nextCenter(center, angle - dAngle);

	float noise0 = valueAtCenter(center, 	  frameNum);
	float noise1 = valueAtCenter(nextCenter1, frameNum);
	float noise2 = valueAtCenter(nextCenter2, frameNum);
	float noise3 = valueAtCenter(nextCenter3, frameNum);

	float dist0 = distanceWeight(coord, center, 	 res);
	float dist1 = distanceWeight(coord, nextCenter1, res);
	float dist2 = distanceWeight(coord, nextCenter2, res);
	float dist3 = distanceWeight(coord, nextCenter3, res);

	// DEBUG
	if (nextCenter1.x < center.x && nextCenter1.y < center.y) {
		
		gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
		return 0.0;
	}
	// if (abs(angle) > PI / 1.1) {
	// //if (angle < 0.0) {
		
	// 	gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
	// 	return 0.0;
	// }

	return (dist0 * noise0 + dist1 * noise1 + dist2 * noise2 + dist3 * noise3) / (dist0 + dist1 + dist2 + dist3);
	//return (dist0 * noise0 + dist1 * noise1 + dist2 * noise2 + dist3 * noise3);
	//return (dist0 * noise0 + dist1 * noise1);
	//return dist0 * noise0;
}*/

float avgBetweenCenters(vec2 center, vec2 coord, float frameNum, float res) {

	float angle = angleBetween(center, coord * res);

	float dAngle = PI / 2.0;

	// Determine 3 surrounding center values and average them
	vec2 centerRight = nextCenter(center, 0.0);
	vec2 centerLeft = nextCenter(center, PI);
	vec2 centerTop = nextCenter(center, PI / 2.0);
	vec2 centerBottom = nextCenter(center, -PI / 2.0);

	float noise0 = valueAtCenter(center, 	  frameNum);
	float noiseRight = valueAtCenter(centerRight, frameNum);
	float noiseLeft = valueAtCenter(centerLeft, frameNum);
	float noiseTop = valueAtCenter(centerTop, frameNum);
	float noiseBottom = valueAtCenter(centerBottom, frameNum);

	float dist0 = distanceWeight(coord, center, 	 res);
	float dist1 = distanceWeight(coord, centerRight, res);
	float dist2 = distanceWeight(coord, centerLeft, res);
	float dist3 = distanceWeight(coord, centerTop, res);
	float dist4 = distanceWeight(coord, centerBottom, res);

	// Top - Bottom
	//return (dist0 * noise0 + dist3 * noiseTop + dist4 * noiseBottom) / (dist0 + dist3 + dist4);

	// Left - Right
	//return (dist0 * noise0 + dist1 * noiseRight + dist2 * noiseLeft) / (dist0 + dist1 + dist2);

	// Top - Bottom - Left - Right
	return (dist0 * noise0 + dist1 * noiseRight + dist2 * noiseLeft + dist3 * noiseTop + dist4 * noiseBottom) / (dist0 + dist1 + dist2 + dist3 + dist4);
	
	//return (dist0 * noise0 + dist1 * noise1 + dist2 * noise2 + dist3 * noise3);
	//return (dist0 * noise0 + dist1 * noise1);
	//return dist0 * noise0;
}

float colorAmountNoise(vec2 coord, float frameNum, float res) {

	vec2 center = centerForCoord(coord, res);

	float noiseVal = valueAtCenter(center, frameNum) * distanceWeight(coord, center, res);

	//float noiseVal = avgBetweenCenters(center, coord, frameNum, res);
    
    //return noiseVal * pow((1.0 - centerDist), 1.5);
    return noiseVal;
}

float colorAmountNoise(vec2 coord, float frameNum) {

	float res = 20.0;
	return colorAmountNoise(coord + 0.5, frameNum, res);
}

float avgColorAmountNoise(vec2 coord, float frameNum) {

	float n1 = colorAmountNoise(vec2(coord[0] - 1.0, coord[1] - 1.0), frameNum);
    float n2 = colorAmountNoise(vec2(coord[0], coord[1] - 1.0), frameNum);
    float n3 = colorAmountNoise(vec2(coord[0] + 1.0, coord[1] - 1.0), frameNum);
    float n4 = colorAmountNoise(vec2(coord[0] - 1.0, coord[1]), frameNum);
    float n5 = colorAmountNoise(vec2(coord[0], coord[1]), frameNum);
    float n6 = colorAmountNoise(vec2(coord[0] + 1.0, coord[1]), frameNum);
    float n7 = colorAmountNoise(vec2(coord[0] - 1.0, coord[1] + 1.0), frameNum);
    float n8 = colorAmountNoise(vec2(coord[0], coord[1] + 1.0), frameNum);
    float n9 = colorAmountNoise(vec2(coord[0] + 1.0, coord[1] + 1.0), frameNum);
    
    return (n1 + n2 + n3 + n4 + n5 + n6 + n7 + n8 + n9) / 5.0;
}

// --------------------    Pressure    ------------------------- // 

highp float fP(highp vec2 pos, highp vec2 center, float dryness) {

	float x = (pos.x - center.x) * 15.0; // * dryness;
	float y = (pos.y - center.y) * 15.0; // * dryness;

	float val = pow(0.5 * (cos(x * sqrt(x * x + y * y)) * cos(y * sqrt(x * x + y * y)) + 1.0), 7.0 * dryness);

	//val = pow(0.5 * (cos(x * 3.0) * cos(y * 3.0) + 1.0), 20.0 * dryness);
	//val = pow(0.5 * (cos(x * pow(x * x + y * y, 0.25) * 3.0) * cos(y * pow(x * x + y * y, 0.25) * 3.0) + 1.0), 7.0 * dryness);

	//return val * 2.0 - 1.0;
	return val;
}

// --------------------    Distortion    ------------------------- // 


highp float parabola(highp vec2 x, highp vec2 center, float multiply) {

	//return pow(min(1.0, length(center - x)), 1.4) * multiply;
	//return length(center - x) * multiply;

	return smoothstep(0.0, 1.0, length(center - x)) * multiply;
}

/// Quadratically increasing value in the direction specified by relativeDirection with the values of 0 being 
/// on the line specified by center.
/// 
/// Example: Multiplying with a vec(1.0, 0.0), with relativeDirection = vec(0.0, 1.0) and center being in the 
/// middle results in the following vector field:
///
/// ---> ---> ---> --->
/// --> --> --> --> -->
/// -> -> -> -> -> -> -
/// . . . . . . . . . .
/// -> -> -> -> -> -> -
/// --> --> --> --> -->
/// ---> ---> ---> --->
///
float quadraticParallelFlow(highp vec2 x, highp vec2 center, highp vec2 relativeDirection, float multiply) {

	float dist = length(dot(center - x, relativeDirection) / length(relativeDirection));
	//return pow(dist, 2.0) * multiply;
	return smoothstep(0.0, 1.0, dist) * multiply;
}

/// Linearly increasing values that simulate compression on one side and expansion on the other side of 
/// a reference line specified by a point (center) and a vector (relativeDirection) pointing in the 
/// direction of compression
///
/// The magnitude of compression 
///
/// Example: Multiplying with a vec(-1.0, 0.0), with relativeDirection = vec(1.0, 0.0) and center being in
/// the middle results in the following vector field:
///
/// <--- <-- <- . <- <----
/// <--- <-- <- . <- <----
/// <--- <-- <- . <- <----
/// <--- <-- <- . <- <----
/// <--- <-- <- . <- <----
/// <--- <-- <- . <- <----
/// <--- <-- <- . <- <----
///
/// - expansion -- comp --
///
float compressionFlow(highp vec2 x, highp vec2 center, highp vec2 relativeDirection, float multiply) {

	highp vec2 dX = center - x;

	float dist = length(dot(dX, relativeDirection) / length(relativeDirection));

	dist = smoothstep(0.0, 1.0, dist) * 1.0;

	float angle = asin(dot(dX, relativeDirection)) / (length(dX) * length(relativeDirection));

	if (angle < 0.0) {
		// compression
		return pow(dist, 1.0) * multiply * 5.0;
	}
	return pow(dist, 1.0) * multiply * 2.0;
}

void markCenter(highp vec2 texturePos, highp vec3 center, highp vec3 color) {

	if (center.z == 0.0) return;

	if (length(texturePos - center.xy) < 0.01) {
		gl_FragColor = vec4(color, 1.0);
	}
}

void main() {

	//highp vec2 textureCoord = vTextureCoord;
	highp vec2 textureCoord = (vTextureCoord - vec2(0.5, 0.5)) * vScaleFactor + vec2(0.5, 0.5);

	float r = 1.0 - abs(textureCoord.x - 0.5) * 2.0;
	float g = 1.0 - abs(textureCoord.y - 0.5) * 2.0;
	//gl_FragColor = vec4(r, g, 0.0, max(r, g));
	//return;
	// DEBUG Markings
	if (min(vTextureCoord.x, vTextureCoord.y) < 0.002 || max(vTextureCoord.x, vTextureCoord.y) > 0.998) {
		//gl_FragColor = vec4(1,1,1,1);
		//return;
	}

	float forceDistWeight = 0.3;
	float linearFlowWeight = 0.1;
	float compressionFlowWeight = 0.04;

	float upMovAngle = (movementDirection + 180.0) * PI / 180.0;
	float upAzmAngle = (azimuth + 180.0) * PI / 180.0;

	float rightMovAngle = upMovAngle + PI / 2.0;
	float downMovAngle = rightMovAngle + PI / 2.0;

	float rightAzmAngle = upAzmAngle + PI / 2.0;
	float downAzmAngle = rightAzmAngle + PI / 2.0;

	float altWeight = min(30.0, (90.0 - altitude)) / 22.5; // ∈ [0, 2]

	highp vec2 center = vec2(0.5, 0.5);
	float azm = -azimuth * PI / 180.0;
	//center += altWeight * 0.25 * vec2(cos(azm), sin(azm));

	highp vec2 rightMov = vec2(cos(-rightMovAngle), sin(-rightMovAngle));
	highp vec2 downMov = vec2(cos(-downMovAngle), sin(-downMovAngle)); 

	highp vec2 rightAzm = vec2(cos(-rightAzmAngle), sin(-rightAzmAngle));
	highp vec2 downAzm = vec2(cos(-downAzmAngle), sin(-downAzmAngle));

	// Distortion caused by the force
	highp vec2 forceDistortion = normalize(center.xy - textureCoord) * parabola(textureCoord, center, force - stiffness) * forceDistWeight;
	// Distortion caused by the movement direction + speed
	highp vec2 linearMovDistortion = quadraticParallelFlow(textureCoord, center, rightMov, max(0.0, speed - stiffness)) * linearFlowWeight * downMov;
	highp vec2 compressMovDistortion = compressionFlow(textureCoord, center, downMov, max(0.0, 2.0 * speed - stiffness)) * compressionFlowWeight * downMov;
	// Distortion caused by the azimuth and altitude angles
	
	highp vec2 linearAngleDistortion = quadraticParallelFlow(textureCoord, center, rightAzm, max(0.0, altWeight)) * linearFlowWeight * (1.0 - stiffness) * downAzm;
	highp vec2 compressAngleDistortion = compressionFlow(textureCoord, center, downAzm, max(0.0, altWeight)) * compressionFlowWeight * downAzm;

	highp vec2 offset = forceDistortion + linearMovDistortion + compressMovDistortion + linearAngleDistortion + compressAngleDistortion;
	//highp vec2 offset = forceDistortion + linearMovDistortion + compressMovDistortion;
	//highp vec2 offset = forceDistortion + compressMovDistortion + compressAngleDistortion;
	//highp vec2 offset = forceDistortion + compressDistortion;

	float maxOffset = 0.3;
	//offset = min(offset, vec2(maxOffset));
	//offset *= maxOffset;

	float dX = offset.x;
	float dY = offset.y;

	//highp vec2 textureCoord = vec2(textureCoord.x + dX, textureCoord.y + dY);
	textureCoord += offset;

	//textureCoord = (textureCoord - vec2(0.5, 0.5)) * vScaleFactor + vec2(0.5, 0.5);

	highp vec4 texColor = texture2D(texture, textureCoord);

	float dryness = 1.0; //fD(textureCoord, center, bristleLength);

	gl_FragColor = vec4(1.0, 1.0, 1.0, texColor.a * dryness);

	highp vec2 vTextureCoordSc = (vTextureCoord - vec2(0.5, 0.5)) * vScaleFactor + vec2(0.5, 0.5);

	//markCenter(vTextureCoordSc, centers(0), vec3(1.0, 0.0, 0.0));
	//markCenter(vTextureCoordSc, centers(1), vec3(0.0, 0.0, 1.0));
	//markCenter(vTextureCoordSc, centers(2), vec3(0.8, 0.8, 0.0));

	bool showNoise = false;

	if (showNoise) {

		
		gl_FragColor = vec4(vec3(colorAmountNoise(textureCoord, frameNum)), 1.0);
		//vec4(vec3(colorAmountNoise(textureCoord, frameNum)), 1.0);
		
		//gl_FragColor.a *= colorAmountNoise(textureCoord, frameNum);
		//gl_FragColor.a *= avgColorAmountNoise(textureCoord, frameNum);
	}
}










