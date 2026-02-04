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

fragment half4 skinProtectFragment(SingleInputVertexIO in [[stage_in]],
                                      texture2d<half> inputTexture [[texture(0)]])
{
  constexpr sampler s(address::clamp_to_edge, filter::linear);
  float3 color = float3(inputTexture.sample(s, in.textureCoordinate).rgb);
  
  // === 计算亮度 ===
  float y = luminance(color);
  
  // === 肤色检测（软 mask）===
  float3 ycbcr = rgbToYCbCr(color);
  float cb = ycbcr.y;
  float cr = ycbcr.z;
  
  float skinMask =
  smoothstep(0.38, 0.42, cb) *
  (1.0 - smoothstep(0.52, 0.56, cb)) *
  smoothstep(0.48, 0.52, cr) *
  (1.0 - smoothstep(0.62, 0.66, cr));
  
  // === 只处理中亮部，保护高光 / 白色 ===
  float midLuma =
  smoothstep(0.20, 0.35, y) *
  (1.0 - smoothstep(0.70, 0.85, y));
  
  float weight = skinMask * midLuma;
  
  // === 目标：轻微提亮（曝光级别）===
  // 这是「摄影意义上的补偿」，不是调色
  float targetY = y * 1.08 + 0.02;
  
  // === 高光 roll-off，防止白色过曝 ===
  targetY = min(targetY, 0.92);
  
  // === 根据亮度比例缩放 RGB（不改色相）===
  float scale = (y > 1e-5) ? (mix(y, targetY, weight) / y) : 1.0;
  float3 corrected = color * scale;
  
  return half4(half3(clamp(corrected, 0.0, 1.0)), 1.0);
}
