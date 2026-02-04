//
//  File.metal
//  GPUImage
//
//  Created by jay on 2/4/26.
//

#include <metal_stdlib>
using namespace metal;

struct TwoInputVertexIO {
  float4 position [[position]];
  float2 textureCoordinate [[user(texturecoord)]];
};

struct LookupUniforms {
  float lutSize;     // N
  float intensity;   // 0..1
};

fragment half4 genericLookupFragment(
                                     TwoInputVertexIO in [[stage_in]],
                                     texture2d<half> inputTexture [[texture(0)]],
                                     texture2d<half> lutTexture   [[texture(1)]],
                                     constant LookupUniforms &u   [[buffer(1)]]
                                     )
{
  constexpr sampler s(address::clamp_to_edge, filter::linear);
  
  // --- 原始颜色 ---
  float3 color = float3(inputTexture.sample(s, in.textureCoordinate).rgb);
  color = clamp(color, 0.0, 1.0);
  
  float size = u.lutSize;
  float maxIndex = size - 1.0;
  
  // --- 映射到 LUT 空间 ---
  float r = color.r * maxIndex;
  float g = color.g * maxIndex;
  float b = color.b * maxIndex;
  
  float r0 = floor(r);
  float g0 = floor(g);
  float b0 = floor(b);
  
  float r1 = min(r0 + 1.0, maxIndex);
  float g1 = min(g0 + 1.0, maxIndex);
  float b1 = min(b0 + 1.0, maxIndex);
  
  float tr = r - r0;
  float tg = g - g0;
  float tb = b - b0;
  
  // --- 2D LUT 坐标计算 ---
  float2 uv000 = float2((r0 + b0 * size + 0.5) / (size * size),
                        (g0 + 0.5) / size);
  float2 uv100 = float2((r1 + b0 * size + 0.5) / (size * size),
                        (g0 + 0.5) / size);
  float2 uv010 = float2((r0 + b0 * size + 0.5) / (size * size),
                        (g1 + 0.5) / size);
  float2 uv110 = float2((r1 + b0 * size + 0.5) / (size * size),
                        (g1 + 0.5) / size);
  
  float2 uv001 = float2((r0 + b1 * size + 0.5) / (size * size),
                        (g0 + 0.5) / size);
  float2 uv101 = float2((r1 + b1 * size + 0.5) / (size * size),
                        (g0 + 0.5) / size);
  float2 uv011 = float2((r0 + b1 * size + 0.5) / (size * size),
                        (g1 + 0.5) / size);
  float2 uv111 = float2((r1 + b1 * size + 0.5) / (size * size),
                        (g1 + 0.5) / size);
  
  // --- 采样 ---
  float3 c000 = float3(lutTexture.sample(s, uv000).rgb);
  float3 c100 = float3(lutTexture.sample(s, uv100).rgb);
  float3 c010 = float3(lutTexture.sample(s, uv010).rgb);
  float3 c110 = float3(lutTexture.sample(s, uv110).rgb);
  float3 c001 = float3(lutTexture.sample(s, uv001).rgb);
  float3 c101 = float3(lutTexture.sample(s, uv101).rgb);
  float3 c011 = float3(lutTexture.sample(s, uv011).rgb);
  float3 c111 = float3(lutTexture.sample(s, uv111).rgb);
  
  // --- 三线性插值 ---
  float3 c00 = mix(c000, c100, tr);
  float3 c10 = mix(c010, c110, tr);
  float3 c01 = mix(c001, c101, tr);
  float3 c11 = mix(c011, c111, tr);
  
  float3 c0 = mix(c00, c10, tg);
  float3 c1 = mix(c01, c11, tg);
  
  float3 lutColor = mix(c0, c1, tb);
  
  // --- 强度混合 ---
  float3 outColor = mix(color, lutColor, u.intensity);
  
  return half4(half3(outColor), 1.0);
}
