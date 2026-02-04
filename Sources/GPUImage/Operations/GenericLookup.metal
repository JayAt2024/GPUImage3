//
//  File.metal
//  GPUImage
//
//  Created by jay on 2/4/26.
//

#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;



struct LookupUniforms {
  float  lutSize;
  float intensity;
};

fragment half4 genericLookupFragment(
                                     SingleInputVertexIO in [[stage_in]],
                                     texture2d<half> inputTexture [[texture(0)]],
                                     texture2d<half> lutTexture   [[texture(1)]],
                                     constant LookupUniforms &u   [[buffer(0)]]
                                     )
{
  constexpr sampler s(address::clamp_to_edge, filter::linear);
  
  float3 color = float3(inputTexture.sample(s, in.textureCoordinate).rgb);
  color = clamp(color, 0.0, 1.0);
  
  float size = u.lutSize;
  float maxIndex = size - 1.0;
  
  float r = color.r * maxIndex;
  float g = color.g * maxIndex;
  float b = color.b * maxIndex;
  
  float x = (r + b * size + 0.5) / (size * size);
  float y = (g + 0.5) / size;
  
  float3 lutColor = float3(lutTexture.sample(s, float2(x, y)).rgb);
  
  float3 outColor = mix(color, lutColor, u.intensity);
  
  return half4(half3(outColor), 1.0);
}
