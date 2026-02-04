//
//  File.metal
//  GPUImage
//
//  Created by jay on 2/4/26.
//

#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

typedef struct
{
  float intensity;
  float lutSize;
} IntensityUniform;


fragment half4 genericLookupFragment(
                                     SingleInputVertexIO in [[stage_in]],
                                     texture2d<half> inputTexture [[texture(0)]],
                                     texture2d<half> lutTexture   [[texture(1)]],
                                     constant IntensityUniform& uniform [[buffer(1)]])
{
  constexpr sampler s(address::clamp_to_edge, filter::linear);
  
  float3 color = float3(inputTexture.sample(s, in.textureCoordinate).rgb);
  
  // Clamp input
  color = clamp(color, 0.0, 1.0);
  
  float size = uniform.lutSize;
  float maxIndex = size - 1.0;
  
  // Convert to LUT space
  float r = color.r * maxIndex;
  float g = color.g * maxIndex;
  float b = color.b * maxIndex;
  
  // Compute LUT UV
  float x = (r + b * size + 0.5) / (size * size);
  float y = (g + 0.5) / size;
  
  float3 lutColor = float3(lutTexture.sample(s, float2(x, y)).rgb);
  
  // Intensity blend (非常重要，安全阀)
  float3 outColor = mix(color, lutColor, uniform.intensity);
  
  return half4(half3(outColor), 1.0);
}
