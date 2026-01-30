#include <metal_stdlib>
#include "OperationShaderTypes.h"
#include "ColorUtils.h"
using namespace metal;

// 油画滤镜参数
typedef struct {
  float brushSize;     // 笔刷大小 (1-10)
  float intensity;     // 效果强度 (0-1)
} OilPaintingUniform;

// 油画效果 Fragment Shader
// 使用 Kuwahara 滤波器创建油画笔触效果

fragment float4 oilPaintingFilter(
                                  SingleInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<float> inputTexture [[texture(0)]],
                                  constant OilPaintingUniform& uniform [[buffer(1)]])
{
  constexpr sampler textureSampler(coord::normalized, filter::linear, address::clamp_to_edge);
  
  float2 textureCoordinate = fragmentInput.textureCoordinate;
  float2 textureSize = float2(inputTexture.get_width(), inputTexture.get_height());
  float2 texelSize = 1.0 / textureSize;
  
  // 限制半径范围，避免过大的采样
  int radius = int(clamp(uniform.brushSize, 1.0f, 10.0f));
  int n = max(radius / 2, 1); // 将区域分成 4 个象限的大小
  
  // 4 个象限的统计数据
  float3 mean[4] = {float3(0.0), float3(0.0), float3(0.0), float3(0.0)};
  float3 squaredMean[4] = {float3(0.0), float3(0.0), float3(0.0), float3(0.0)};
  int count[4] = {0, 0, 0, 0};
  
  // 采样 4 个象限
  // Kuwahara 滤波器：将窗口分为 4 个重叠的象限，选择方差最小的象限
  for (int dy = -radius; dy <= radius; dy++) {
    for (int dx = -radius; dx <= radius; dx++) {
      float2 offset = float2(float(dx), float(dy)) * texelSize;
      float2 sampleCoord = textureCoordinate + offset;
      
      // 边界检查
      sampleCoord = clamp(sampleCoord, float2(0.0), float2(1.0));
      
      float4 color = inputTexture.sample(textureSampler, sampleCoord);
      float3 rgb = float3(color.rgb);
      
      // 确定属于哪个象限（四个重叠的正方形区域）
      // 象限 0: 右下 (x >= 0, y >= 0)
      // 象限 1: 左下 (x <= 0, y >= 0)
      // 象限 2: 左上 (x <= 0, y <= 0)
      // 象限 3: 右上 (x >= 0, y <= 0)
      
      if (dx >= -n && dx <= 0 && dy >= -n && dy <= 0) {
        // 左上象限
        mean[2] += rgb;
        squaredMean[2] += rgb * rgb;
        count[2]++;
      }
      if (dx >= 0 && dx <= n && dy >= -n && dy <= 0) {
        // 右上象限
        mean[3] += rgb;
        squaredMean[3] += rgb * rgb;
        count[3]++;
      }
      if (dx >= -n && dx <= 0 && dy >= 0 && dy <= n) {
        // 左下象限
        mean[1] += rgb;
        squaredMean[1] += rgb * rgb;
        count[1]++;
      }
      if (dx >= 0 && dx <= n && dy >= 0 && dy <= n) {
        // 右下象限
        mean[0] += rgb;
        squaredMean[0] += rgb * rgb;
        count[0]++;
      }
    }
  }
  
  // 计算每个象限的平均值和方差，选择方差最小的
  float minVariance = 1e10;
  float3 resultColor = float3(0.0);
  
  for (int i = 0; i < 4; i++) {
    if (count[i] > 0) {
      // 计算平均值
      mean[i] /= float(count[i]);
      
      // 计算方差: Var(X) = E[X²] - E[X]²
      float3 variance = squaredMean[i] / float(count[i]) - mean[i] * mean[i];
      
      // 总方差（所有通道的和）
      float totalVariance = variance.r + variance.g + variance.b;
      
      // 选择方差最小的象限（颜色最均匀的区域）
      if (totalVariance < minVariance) {
        minVariance = totalVariance;
        resultColor = mean[i];
      }
    }
  }
  
  // 采样原始颜色
  float4 originalColor = inputTexture.sample(textureSampler, textureCoordinate);
  
  // 混合原始颜色和油画效果
  float mixAmount = clamp(uniform.intensity, 0.0f, 1.0f);
  float3 mixedColor = mix(float3(originalColor.rgb), resultColor, mixAmount);
  
  // 增加饱和度和对比度，模拟油画的浓郁色彩
  float3 hsv = rgbToHsv(mixedColor);
  hsv.y = saturate(hsv.y * 1.3);                    // 增加饱和度 30%
  hsv.z = saturate((hsv.z - 0.5) * 1.2 + 0.5);     // 增加对比度 20%
  float3 finalColor = hsvToRgb(hsv);
  
  return float4(finalColor, originalColor.a);
}

