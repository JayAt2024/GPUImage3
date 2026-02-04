//
//  File.metal
//  GPUImage
//
//  Created by jay on 2/4/26.
//

#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

// RGB → YCbCr（BT.601）
inline float3 rgbToYCbCr(float3 rgb) {
  float y  = dot(rgb, float3(0.299, 0.587, 0.114));
  float cb = (rgb.b - y) * 0.564 + 0.5;
  float cr = (rgb.r - y) * 0.713 + 0.5;
  return float3(y, cb, cr);
}

// Uniform 结构体用于传递参数
struct SkinProtectUniforms {
  float skinLift;
  float skinBlueReduce;
};

fragment half4 skinProtectFragment(SingleInputVertexIO in [[stage_in]],
                                   texture2d<half> inputTexture [[texture(0)]],
                                   constant SkinProtectUniforms &uniforms [[buffer(1)]])
{
  constexpr sampler s(address::clamp_to_edge, filter::linear);
  float3 color = float3(inputTexture.sample(s, in.textureCoordinate).rgb);
  
  // 转 YCbCr
  float3 ycbcr = rgbToYCbCr(color);
  float y  = ycbcr.x;
  float cb = ycbcr.y;
  float cr = ycbcr.z;
  
  // 肤色判定区间
  bool isSkin =
  cb > 0.38 && cb < 0.52 &&
  cr > 0.48 && cr < 0.62 &&
  y  > 0.15;
  
  if (isSkin) {
    // 使用传入的参数
    color += uniforms.skinLift;       // 提亮
    color.b -= uniforms.skinBlueReduce; // 减少蓝光
    color.r += 0.01;                  // 轻微暖肤（固定值）
  }
  
  return half4(half3(clamp(color, 0.0, 1.0)), 1.0);
}
