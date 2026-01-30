#include <metal_stdlib>
#include "OperationShaderTypes.h"
#include "ColorUtils.h"
using namespace metal;

typedef struct {
  float edgeStrength;
  float colorLevels;
  float textureStrength;
  float padding; // 对齐用（很重要）
} CrayonUniform;

fragment float4 crayonFilter(SingleInputVertexIO fragmentInput [[stage_in]],
                             texture2d<float, access::sample> inputTexture [[texture(0)]],
                             constant CrayonUniform& u [[buffer(1)]])
{
  constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
  
  float2 uv = fragmentInput.textureCoordinate;
  float2 texSize = float2(inputTexture.get_width(), inputTexture.get_height());
  float2 texel = 1.0 / texSize;
  
  float4 centerColor = inputTexture.sample(s, uv);
  
  // === Sobel 边缘 ===
  float gx = 0.0;
  float gy = 0.0;
  
  float sobelX[3][3] = {
    {-1, 0, 1},
    {-2, 0, 2},
    {-1, 0, 1}
  };
  
  float sobelY[3][3] = {
    {-1, -2, -1},
    { 0,  0,  0},
    { 1,  2,  1}
  };
  
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      float2 offset = float2(x, y) * texel;
      float3 c = inputTexture.sample(s, uv + offset).rgb;
      float lum = dot(c, float3(0.299, 0.587, 0.114));
      gx += lum * sobelX[y + 1][x + 1];
      gy += lum * sobelY[y + 1][x + 1];
    }
  }
  
  float edge = saturate(length(float2(gx, gy)) * u.edgeStrength);
  
  // === 颜色量化 ===
  float levels = max(u.colorLevels, 3.0);
  float3 q = floor(centerColor.rgb * levels + 0.5) / levels;
  
  float3 hsv = rgbToHsv(q);
  hsv.y *= 0.7;
  hsv.z = saturate(hsv.z * 1.1 + 0.05);
  q = hsvToRgb(hsv);
  
  // === 纸张纹理 ===
  float grain = fract(sin(dot(uv * texSize, float2(12.9898,78.233))) * 43758.5453);
  q *= mix(1.0, grain, u.textureStrength);
  
  float3 edgeColor = float3(0.1, 0.1, 0.15);
  float3 finalColor = mix(q, edgeColor, edge);
  
  return float4(saturate(finalColor), centerColor.a);
}
