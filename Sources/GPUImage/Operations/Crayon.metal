#include <metal_stdlib>
#include "OperationShaderTypes.h"
#include "ColorUtils.h"
using namespace metal;


// GPUImage3 风格 uniform
typedef struct {
  float edgeStrength;      // 边缘强度
  float colorLevels;       // 颜色量化等级
  float textureStrength;   // 纹理颗粒强度
  float padding;           // 对齐
} CrayonUniform;

fragment float4 crayonFilter(
                             SingleInputVertexIO fragmentInput [[stage_in]],
                             texture2d<float, access::sample> inputTexture [[texture(0)]],
                             constant CrayonUniform& u [[buffer(1)]]
                             ) {
                               constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
                               
                               float2 uv = fragmentInput.textureCoordinate;
                               float2 texSize = float2(inputTexture.get_width(), inputTexture.get_height());
                               float2 texel = 1.0 / texSize;
                               
                               float4 centerColor = inputTexture.sample(s, uv);
                               
                               // === 1. Sobel 边缘检测 ===
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
                                   float lum = dot(c, float3(0.299,0.587,0.114));
                                   gx += lum * sobelX[y + 1][x + 1];
                                   gy += lum * sobelY[y + 1][x + 1];
                                 }
                               }
                               
                               float edge = saturate(length(float2(gx, gy)) * u.edgeStrength);
                               
                               // === 2. 颜色量化 ===
                               float levels = max(u.colorLevels, 3.0);
                               float3 qColor = floor(centerColor.rgb * levels + 0.5) / levels;
                               
                               // 柔化饱和度和亮度，让蜡笔色块自然
                               float3 hsv = rgbToHsv(qColor);
                               hsv.y = saturate(hsv.y * 0.75);  // 稍微降低饱和度
                               hsv.z = saturate(hsv.z * 1.05 + 0.02); // 微调亮度
                               qColor = hsvToRgb(hsv);
                               
                               // === 3. 柔和颗粒感（轻微噪声） ===
                               float grain = sin(dot(uv * texSize, float2(12.9898,78.233))) * 43758.5453;
                               grain = fract(grain);
                               // 使用平滑函数减少颗粒突兀
                               grain = pow(grain, 1.5);
                               qColor *= mix(1.0, 0.95 + 0.05 * grain, u.textureStrength);
                               
                               // === 4. 混合边缘 ===
                               float3 edgeColor = float3(0.1, 0.1, 0.15);
                               float3 finalColor = mix(qColor, edgeColor, edge);
                               
                               return float4(saturate(finalColor), centerColor.a);
                             }
