//
//  File.metal
//  GPUImage
//
//  Created by jay on 2/4/26.
//

#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

inline float luminance(float3 c) {
  return dot(c, float3(0.299, 0.587, 0.114));
}

inline float3 rgbToYCbCr(float3 rgb) {
  float y  = luminance(rgb);
  float cb = (rgb.b - y) * 0.564 + 0.5;
  float cr = (rgb.r - y) * 0.713 + 0.5;
  return float3(y, cb, cr);
}

fragment half4 skinProtectFragment_v2(SingleInputVertexIO in [[stage_in]],
                                      texture2d<half> inputTexture [[texture(0)]])
{
  constexpr sampler s(address::clamp_to_edge, filter::linear);
  float3 color = float3(inputTexture.sample(s, in.textureCoordinate).rgb);
  
  float3 ycbcr = rgbToYCbCr(color);
  float y  = ycbcr.x;
  float cb = ycbcr.y;
  float cr = ycbcr.z;
  
  // —— 肤色 mask（软判定）——
  float skinMask =
  smoothstep(0.38, 0.42, cb) *
  (1.0 - smoothstep(0.52, 0.56, cb)) *
  smoothstep(0.48, 0.52, cr) *
  (1.0 - smoothstep(0.62, 0.66, cr));
  
  // —— 亮度权重（只处理中亮）——
  float midLuma =
  smoothstep(0.20, 0.35, y) *
  (1.0 - smoothstep(0.75, 0.90, y));
  
  float weight = skinMask * midLuma;
  
  // === 目标肤色（温暖但不过） ===
  float3 target = color;
  target.r += 0.025;
  target.b -= 0.025;
  
  // —— 防止白色偏绿：向亮度回归一点 ——
  float lum = luminance(color);
  float3 neutral = float3(lum);
  
  // 混合：先肤色修正，再白平衡修正
  float3 corrected =
  mix(color, target, weight);
  
  corrected =
  mix(corrected, neutral, weight * smoothstep(0.65, 0.85, y));
  
  return half4(half3(clamp(corrected, 0.0, 1.0)), 1.0);
}
