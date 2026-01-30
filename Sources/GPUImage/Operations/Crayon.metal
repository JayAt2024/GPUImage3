#include <metal_stdlib>
#include "ColorUtils.h"
using namespace metal;

// 蜡笔画效果 Fragment Shader
// 结合边缘检测、纹理和颜色量化

typedef struct {
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
} SingleInputVertexIO;

fragment half4 crayonFilter(SingleInputVertexIO fragmentInput [[stage_in]],
                            texture2d<half> inputTexture [[texture(0)]],
                            constant float &edgeStrength [[buffer(1)]],
                            constant float &colorLevels [[buffer(2)]],
                            constant float &textureStrength [[buffer(3)]])
{
    constexpr sampler textureSampler(coord::normalized, filter::linear, address::clamp_to_edge);
    
    float2 textureCoordinate = fragmentInput.textureCoordinate;
    float2 textureSize = float2(inputTexture.get_width(), inputTexture.get_height());
    float2 texelSize = 1.0 / textureSize;
    
    // 读取原始颜色
    half4 centerColor = inputTexture.sample(textureSampler, textureCoordinate);
    
    // === 1. 边缘检测（Sobel 算子）===
    float3 sobelX = float3(0.0);
    float3 sobelY = float3(0.0);
    
    // Sobel 卷积核
    const float sobelKernelX[3][3] = {
        {-1.0, 0.0, 1.0},
        {-2.0, 0.0, 2.0},
        {-1.0, 0.0, 1.0}
    };
    
    const float sobelKernelY[3][3] = {
        {-1.0, -2.0, -1.0},
        { 0.0,  0.0,  0.0},
        { 1.0,  2.0,  1.0}
    };
    
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            float2 offset = float2(float(dx), float(dy)) * texelSize;
            float2 sampleCoord = clamp(textureCoordinate + offset, float2(0.0), float2(1.0));
            
            half3 color = inputTexture.sample(textureSampler, sampleCoord).rgb;
            float intensity = dot(float3(color), float3(0.299, 0.587, 0.114)); // 转换为灰度
            
            sobelX += intensity * sobelKernelX[dy + 1][dx + 1];
            sobelY += intensity * sobelKernelY[dy + 1][dx + 1];
        }
    }
    
    float edgeMagnitude = length(float2(length(sobelX), length(sobelY)));
    edgeMagnitude = saturate(edgeMagnitude * edgeStrength);
    
    // === 2. 颜色量化（蜡笔效果）===
    float3 quantizedColor = float3(centerColor.rgb);
    
    // 将颜色量化到有限的色阶
    float levels = max(colorLevels, 3.0);
    quantizedColor = floor(quantizedColor * levels + 0.5) / levels;
    
    // 降低饱和度，增加粉笔感
    float3 hsv = rgbToHsv(quantizedColor);
    hsv.y = saturate(hsv.y * 0.7); // 降低饱和度
    hsv.z = saturate(hsv.z * 1.1 + 0.05); // 略微提亮
    quantizedColor = hsvToRgb(hsv);
    
    // === 3. 程序化纸张纹理 ===
    float2 texCoord = textureCoordinate * 3.0; // 重复纹理
    
    // 程序化噪声纹理
    float paperGrain = fract(sin(dot(texCoord, float2(12.9898, 78.233))) * 43758.5453);
    paperGrain = paperGrain * 0.5 + 0.5; // 调整范围
    
    // === 4. 合成最终效果 ===
    // 应用纹理
    float3 texturedColor = quantizedColor * mix(1.0, paperGrain, textureStrength);
    
    // 应用边缘（深色边缘）
    float3 edgeColor = float3(0.1, 0.1, 0.15); // 深蓝灰色边缘
    float3 finalColor = mix(texturedColor, edgeColor, edgeMagnitude);
    
    // 添加轻微的颗粒感
    float grain = fract(sin(dot(textureCoordinate * textureSize, float2(12.9898, 78.233))) * 43758.5453);
    finalColor += (grain - 0.5) * 0.03;
    
    finalColor = saturate(finalColor);
    
    return half4(half3(finalColor), centerColor.a);
}
