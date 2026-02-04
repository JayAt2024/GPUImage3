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
  
  // --------------------------------------------------
  // 1. Sample input color
  // --------------------------------------------------
  float3 color = float3(inputTexture.sample(s, in.textureCoordinate).rgb);
  color = clamp(color, 0.0, 1.0);
  
  float size = u.lutSize;
  float maxIndex = size - 1.0;
  
  // --------------------------------------------------
  // 2. Map RGB -> LUT index space
  // --------------------------------------------------
  float r = color.r * maxIndex;
  float g = color.g * maxIndex;
  float b = color.b * maxIndex;
  
  // --------------------------------------------------
  // 3. Integer indices + fractions
  // --------------------------------------------------
  float r0 = floor(r);
  float r1 = min(r0 + 1.0, maxIndex);
  float fr = r - r0;
  
  float g0 = floor(g);
  float g1 = min(g0 + 1.0, maxIndex);
  float fg = g - g0;
  
  float b0 = floor(b);
  float b1 = min(b0 + 1.0, maxIndex);
  float fb = b - b0;
  
  // --------------------------------------------------
  // 4. Compute LUT UVs (2D-packed 3D LUT)
  // width  = size * size
  // height = size
  // --------------------------------------------------
  float invWidth  = 1.0 / (size * size);
  float invHeight = 1.0 / size;
  
  float2 uv000 = float2((b0 * size + r0 + 0.5) * invWidth,
                        (g0 + 0.5) * invHeight);
  
  float2 uv100 = float2((b0 * size + r1 + 0.5) * invWidth,
                        (g0 + 0.5) * invHeight);
  
  float2 uv010 = float2((b0 * size + r0 + 0.5) * invWidth,
                        (g1 + 0.5) * invHeight);
  
  float2 uv110 = float2((b0 * size + r1 + 0.5) * invWidth,
                        (g1 + 0.5) * invHeight);
  
  float2 uv001 = float2((b1 * size + r0 + 0.5) * invWidth,
                        (g0 + 0.5) * invHeight);
  
  float2 uv101 = float2((b1 * size + r1 + 0.5) * invWidth,
                        (g0 + 0.5) * invHeight);
  
  float2 uv011 = float2((b1 * size + r0 + 0.5) * invWidth,
                        (g1 + 0.5) * invHeight);
  
  float2 uv111 = float2((b1 * size + r1 + 0.5) * invWidth,
                        (g1 + 0.5) * invHeight);
  
  // --------------------------------------------------
  // 5. Sample 8 corners
  // --------------------------------------------------
  float3 c000 = float3(lutTexture.sample(s, uv000).rgb);
  float3 c100 = float3(lutTexture.sample(s, uv100).rgb);
  float3 c010 = float3(lutTexture.sample(s, uv010).rgb);
  float3 c110 = float3(lutTexture.sample(s, uv110).rgb);
  
  float3 c001 = float3(lutTexture.sample(s, uv001).rgb);
  float3 c101 = float3(lutTexture.sample(s, uv101).rgb);
  float3 c011 = float3(lutTexture.sample(s, uv011).rgb);
  float3 c111 = float3(lutTexture.sample(s, uv111).rgb);
  
  // --------------------------------------------------
  // 6. Trilinear interpolation
  // --------------------------------------------------
  float3 c00 = mix(c000, c100, fr);
  float3 c10 = mix(c010, c110, fr);
  float3 c01 = mix(c001, c101, fr);
  float3 c11 = mix(c011, c111, fr);
  
  float3 c0 = mix(c00, c10, fg);
  float3 c1 = mix(c01, c11, fg);
  
  float3 lutColor = mix(c0, c1, fb);
  
  // --------------------------------------------------
  // 7. Intensity blend
  // --------------------------------------------------
  float3 outColor = mix(color, lutColor, u.intensity);
  
  return half4(half3(outColor), 1.0);
}
