#version 330

in vec3 vViewSpaceNormal;
in vec3 vViewSpacePosition;
in vec2 vTexCoords;

uniform vec3 uLightDirection;
uniform vec3 uLightIntensity;

uniform vec4 uBaseColorFactor;

uniform float uMetallicFactor;
uniform float uRoughnessFactor;
uniform sampler2D uMetallicRoughnessTexture;

uniform sampler2D uBaseColorTexture;

out vec3 fColor;

// Constants
const float GAMMA = 2.2;
const float INV_GAMMA = 1. / GAMMA;
const float M_PI = 3.141592653589793;
const float M_1_PI = 1.0 / M_PI;

// We need some simple tone mapping functions
// Basic gamma = 2.2 implementation
// Stolen here: https://github.com/KhronosGroup/glTF-Sample-Viewer/blob/master/src/shaders/tonemapping.glsl

// linear to sRGB approximation
// see http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
vec3 LINEARtoSRGB(vec3 color)
{
  return pow(color, vec3(INV_GAMMA));
}

// sRGB to linear approximation
// see http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
vec4 SRGBtoLINEAR(vec4 srgbIn)
{
  return vec4(pow(srgbIn.xyz, vec3(GAMMA)), srgbIn.w);
}

void main()
{
  vec3 N = normalize(vViewSpaceNormal);
  vec3 L = uLightDirection;
  vec3 V = normalize(-vViewSpacePosition);
  vec3 H = normalize(L + V);

  vec4 baseColorFromTexture = SRGBtoLINEAR(texture(uBaseColorTexture, vTexCoords));
  vec4 metallicRoughnessFromTexture = texture(uMetallicRoughnessTexture, vTexCoords);

  vec4 baseColor = baseColorFromTexture * uBaseColorFactor;
  vec3 metallic = vec3(uMetallicFactor * metallicRoughnessFromTexture.b);
  float roughness = uRoughnessFactor * metallicRoughnessFromTexture.g;

  //

  vec3 dielectricSpecular = vec3(0.04, 0.04, 0.04);
  vec3 black = vec3(0, 0, 0);

  vec3 cdiff = mix(baseColor.rgb * (1 - dielectricSpecular.r), black, metallic);
  vec3 F0 = mix(dielectricSpecular, baseColor.rgb, metallic);
  float alpha = roughness * roughness;

  float NdotL = clamp(dot(N, L), 0, 1);
  float NdotV = clamp(dot(N, V), 0, 1);
  float VdotH = clamp(dot(V, H), 0, 1);
  float NdotH = clamp(dot(N, H), 0, 1);

  vec3 diffuse = cdiff / M_PI;

  float Vis;
  if( NdotV * sqrt( NdotL * NdotL * (1 - alpha * alpha) + alpha * alpha ) == 0 ) {
    Vis = 0;
  } else {
    Vis = (0.5) / NdotL * sqrt( NdotV * NdotV * (1 - alpha * alpha) + alpha * alpha )
        + NdotV * sqrt( NdotL * NdotL * (1 - alpha * alpha) + alpha * alpha );
  
  }

  float baseShlickFactor = (1 - VdotH);
  float shlickFactor = baseShlickFactor * baseShlickFactor;
  shlickFactor *= shlickFactor;
  shlickFactor *= baseShlickFactor;

  vec3 F = F0 + (1 - F0) * shlickFactor;

  vec3 f_diffuse = (1 - F) * diffuse;

  
  float D = (alpha * alpha)
  / (M_PI * ( (NdotH * NdotH * (alpha * alpha - 1) + 1) * (NdotH * NdotH * (alpha * alpha - 1) + 1)) ) ;

  vec3 f_specular = F * Vis * D;

  vec3 f = f_diffuse + f_specular;

  //
  
  fColor = LINEARtoSRGB(f * uLightIntensity * NdotL);
}
