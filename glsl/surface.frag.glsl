precision highp float;

#define SAMPLE_SLOTS 5
#extension GL_OES_standard_derivatives : enable

uniform mat4 uGeocastMVPMatrix[SAMPLE_SLOTS];
uniform sampler2D texGeocastSampler[SAMPLE_SLOTS];
uniform float uBoundSlots;

varying vec4 pass_discardFlag;
varying vec4 pass_aPosition;
varying vec3 pass_barycentricCoords;
uniform float uShowWireframe;

bool inFrustum(mat4 M, vec4 p) 
{
  vec4 Pclip = M * p;
  return abs(Pclip.x) <= Pclip.w && abs(Pclip.y) <= Pclip.w && 
    0. <= abs(Pclip.z) && abs(Pclip.z) <= Pclip.w;
}

float edgeFactor() 
{
  vec3 d = fwidth(pass_barycentricCoords);
  vec3 a3 = smoothstep(vec3(0.0), d*1.0, pass_barycentricCoords);
  return min(min(a3.x, a3.y), a3.z);
}

void main(void) 
{  
  //  if(pass_discardFlag.a < 0.999)
  //  discard;

  gl_FragColor = vec4(1.0); //vec2(1.0) - pass_aPosition.xy, 0.0, 1.0);


#if 1
  if(uShowWireframe == 0.0) 
    { // Texture lookup shading    
      vec4 latticeBackground = vec4(0.1, 0.1, 0.1, 1.0); // Default to gray if no texture is present
      
      vec4 aPosition = pass_aPosition;
      
      vec4 final_color = latticeBackground;
      bool backgroundColor = true;
      
      for (int i = 0; i < SAMPLE_SLOTS; ++i) 
	{
	  if (float(i) >= uBoundSlots)
	    break;
	  
	  if (inFrustum(uGeocastMVPMatrix[i], aPosition))
	    {
	      // In-projector region, do a texture lookup
	      vec4 Pclip = uGeocastMVPMatrix[i] * aPosition;
	      vec2 texture_uv = vec2((Pclip.x + Pclip.w) / (2. * Pclip.w), (Pclip.y + Pclip.w) / (2. * Pclip.w));
	      vec4 texel = texture2D(texGeocastSampler[i], texture_uv);
	      
	      if (backgroundColor) 
		{ // Substitute the background color if this is the first match
		  backgroundColor = false;
		  final_color = texel;
		} 
	      else 
		{
		  final_color = mix(final_color, texel, 0.5);
		}
	    }
	}

      gl_FragColor = final_color;
    } 
  else 
    { // Wireframe anti-aliased shading and white fragments
    gl_FragColor.rgb = vec3(edgeFactor()*0.95);
    gl_FragColor.a = 1.0;
  }

#endif
}
