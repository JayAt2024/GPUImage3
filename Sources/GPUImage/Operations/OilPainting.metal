#include <metal_stdlib>
#include "OperationShaderTypes.h"
#include "ColorUtils.h"
using namespace metal;

// 蜡笔滤镜参数
typedef struct {
  float brushSize;
  float intensity;
} OilPaintingUniform;

// 油画效果 Fragment Shader
// 使用 Kuwahara 滤波器创建油画笔触效果

fragment half4 oilPaintingFilter(SingleInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                 constant OilPaintingUniform& uniform [[buffer(1)]])
{
    constexpr sampler textureSampler(coord::normalized, filter::linear, address::clamp_to_edge);
    
    float2 textureCoordinate = fragmentInput.textureCoordinate;
    float2 textureSize = float2(inputTexture.get_width(), inputTexture.get_height());
    float2 texelSize = 1.0 / textureSize;
    
    int radius = int(uniform.brushSize);
    int n = max(radius / 2, 1); // 将区域分成 4 个象限
    
    // 4 个象限的统计数据
    float3 mean[4] = {float3(0.0), float3(0.0), float3(0.0), float3(0.0)};
    float3 variance[4] = {float3(0.0), float3(0.0), float3(0.0), float3(0.0)};
    int count[4] = {0, 0, 0, 0};
    
    // 采样 4 个象限
    for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
            float2 offset = float2(dx, dy) * texelSize;
            float2 sampleCoord = textureCoordinate + offset;
            
            // 边界检查
            sampleCoord = clamp(sampleCoord, float2(0.0), float2(1.0));
            
            half4 color = inputTexture.sample(textureSampler, sampleCoord);
            float3 rgb = float3(color.rgb);
            
            // 确定属于哪个象限
            int quadrant = -1;
            if (dx >= 0 && dy >= 0 && dx <= n && dy <= n) quadrant = 0;      // 右下
            else if (dx < 0 && dy >= 0 && dx >= -n && dy <= n) quadrant = 1; // 左下
            else if (dx < 0 && dy < 0 && dx >= -n && dy >= -n) quadrant = 2; // 左上
            else if (dx >= 0 && dy < 0 && dx <= n && dy >= -n) quadrant = 3; // 右上
            
            if (quadrant >= 0) {
                mean[quadrant] += rgb;
                variance[quadrant] += rgb * rgb;
                count[quadrant]++;
            }
        }
    }
    
    // 计算每个象限的平均值和方差
    float minVariance = 1e10;
    float3 resultColor = float3(0.0);
    
    for (int i = 0; i < 4; i++) {
        if (count[i] > 0) {
            mean[i] /= float(count[i]);
            variance[i] = variance[i] / float(count[i]) - mean[i] * mean[i];
            float totalVariance = variance[i].r + variance[i].g + variance[i].b;
            
            // 选择方差最小的象限（最均匀的颜色）
            if (totalVariance < minVariance) {
                minVariance = totalVariance;
                resultColor = mean[i];
            }
        }
    }
    
    // 混合原始颜色和油画效果
    half4 originalColor = inputTexture.sample(textureSampler, textureCoordinate);
    float3 finalColor = mix(float3(originalColor.rgb), resultColor, uniform.intensity);
    
    // 增加饱和度和对比度，模拟油画的浓郁色彩
    float3 hsv = rgbToHsv(finalColor);
    hsv.y = saturate(hsv.y * 1.3); // 增加饱和度
    hsv.z = saturate((hsv.z - 0.5) * 1.2 + 0.5); // 增加对比度
    finalColor = hsvToRgb(hsv);
    
    return half4(half3(finalColor), originalColor.a);
}
