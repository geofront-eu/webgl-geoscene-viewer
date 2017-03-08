precision highp float;
attribute vec4 aPosition; // Lattice data

// Scene data
uniform mat4 uViewMVMatrix;
uniform mat4 uViewProjMatrix;
// Floor data
uniform mat4 uFloorMVMatrix;
uniform mat4 uFloorProjMatrix;
uniform mat4 uFloorMVMatrix_Inverse;
uniform mat4 uFloorProjMatrix_Inverse;
uniform vec2 uFloorClipRange;

uniform sampler2D texDepthMapSampler;

varying vec4 pass_discardFlag;
varying vec4 pass_aPosition;
varying vec3 pass_barycentricCoords;

uniform vec2 delta; 

vec2 posoffset(float vertex_id)
{
  if (vertex_id == 0.0) return vec2(0, 0);
  if (vertex_id == 1.0) return vec2(1, 0);
  if (vertex_id == 0.1) return vec2(0, 1); 
  if (vertex_id == 1.1) return vec2(1, 1); 

  return vec2(-0.5); // should never end up here
}

vec3 barycentric(vec4 inpos)
{
  if (inpos.w == 0.0)
    return vec3(inpos.z == 0.0, inpos.z == 1.0, inpos.z == 0.1);

  if (inpos.w == 1.0)
    return vec3(inpos.z == 1.0, inpos.z == 1.1, inpos.z == 0.1);

  if (inpos.w == 2.0)
    return vec3(inpos.z == 0.0, inpos.z == 1.0, inpos.z == 1.1);

  if (inpos.w == 3.0)
    return vec3(inpos.z == 0.0, inpos.z == 1.1, inpos.z == 0.1);

  return vec3(1.0); // should never end up here
}

bool valid(float depth) { return depth < 1.0; }

void main(void) 
{
  vec4 inpos = aPosition; 
  
#if 1 // expensive check, but allows for proper cancellation of any triangle that connects to pixels on backplane or infinity Z
  bool triangle_complete = false;

  float depth00 = texture2D(texDepthMapSampler, inpos.xy + vec2(0, 0) * delta).x;
  float depth10 = texture2D(texDepthMapSampler, inpos.xy + vec2(1, 0) * delta).x;
  float depth01 = texture2D(texDepthMapSampler, inpos.xy + vec2(0, 1) * delta).x;
  float depth11 = texture2D(texDepthMapSampler, inpos.xy + vec2(1, 1) * delta).x;

  if (inpos.w == 0.0)
    if (valid(depth00) &&    //  00-10 : Triangle type 0
	valid(depth10) &&    //  | /
	valid(depth01))      //  01
      triangle_complete = true; 

  if (inpos.w == 1.0)
    if (valid(depth10) &&     //     10 : Triangle type 1
	valid(depth01) &&     //    / |	
	valid(depth11))       //  01-11
      triangle_complete = true; 

  if (inpos.w == 2.0)
    if (valid(depth00) &&     //  00-10 : Triangle type 2
	valid(depth10) &&     //    \ |	
	valid(depth11))       //     11
      triangle_complete = true; 

  if (inpos.w == 3.0)
    if (valid(depth00) &&     //  00   : Triangle type 3
	valid(depth01) &&     //  | \	
	valid(depth11))       //  01-11
      triangle_complete = true; 
  
  if (triangle_complete) 
#endif
    {
      vec2 texpos = inpos.xy + posoffset(inpos.z) * delta;
      
      // deduce the barycentric coords from inpos (triangle type and vertex ID)
      pass_barycentricCoords = barycentric(inpos); 
      
      vec4 depth = texture2D(texDepthMapSampler, texpos);

      // For Worldspace Depth Values: 
      // "image" a pixel of depth Z (its view vector) into camera space
      vec4 depth_camspace = 
	uFloorProjMatrix * 
	vec4(0.0, 0.0, mix(-uFloorClipRange.x, -uFloorClipRange.y, depth.x), 1.);

      float model_depth = depth_camspace.z / depth_camspace.w;

      // Lattice has coords [0;1], this doesn't use the full screen extents of the projector [-1;1]. Rescale
      vec2 latticePos = texpos * 2.0 - vec2(1.0);

      vec4 worldpos = uFloorMVMatrix * uFloorProjMatrix_Inverse * vec4(latticePos.xy,  model_depth, 1);
      pass_aPosition = worldpos;
      
      //worldpos = vec4(0, 0, 0, 1.0);
      //worldpos = vec4(texpos*2.0, 0.0, 1.0);
      
      gl_PointSize = 1.0; 
      gl_Position = worldpos;
      gl_Position = uViewProjMatrix * uViewMVMatrix * worldpos;
    }
}
