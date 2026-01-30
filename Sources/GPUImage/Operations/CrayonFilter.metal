#include <metal_stdlib>
#include "OperationShaderTypes.h"
#include "ColorUtils.h"
using namespace metal;

// 蜡笔滤镜参数
typedef struct {
    float strokeLength;        // 笔触长度 (0.5-2.0)
    float strokeDensity;       // 笔触密度 (3.0-8.0)
    float paperGrainStrength;  // 纸张纹理强度 (0.1-0.5)
    float saturationBoost;     // 饱和度增强 (1.1-1.4)
    float edgeStrength;        // 边缘强度 (0.3-0.8)
    float colorLevels;         // 颜色量化级别 (6-12)
    float waxGlossiness;       // 蜡质光泽度 (0.1-0.4)
    float strokeAngleVar;      // 笔触角度变化 (0.0-0.3)
} CrayonUniform;

// ============ 辅助函数 ============

// 哈希函数 - 生成伪随机值
float hash(float2 p) {
    float h = dot(p, float2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

// 2D哈希函数
float2 hash2(float2 p) {
    return fract(sin(float2(dot(p, float2(127.1, 311.7)),
                             dot(p, float2(269.5, 183.3)))) * 43758.5453);
}

// 平滑噪声
float smoothNoise(float2 uv) {
    float2 i = floor(uv);
    float2 f = fract(uv);
    
    // 平滑插值
    f = f * f * (3.0 - 2.0 * f);
    
    // 四个角的随机值
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    
    // 双线性插值
    return mix(mix(a, b, f.x),
               mix(c, d, f.x), f.y);
}

// 分形噪声 - 多个八度的噪声叠加
float fractalNoise(float2 uv, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * smoothNoise(uv * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

// 2D旋转
float2 rotate(float2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return float2(v.x * c - v.y * s, v.x * s + v.y * c);
}

// 计算亮度
float getLuminance(float3 color) {
    return dot(color, float3(0.299, 0.587, 0.114));
}

// Voronoi噪声 - 用于创建更自然的笔触纹理
float voronoiNoise(float2 uv) {
    float2 i = floor(uv);
    float2 f = fract(uv);
    
    float minDist = 1.0;
    
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 neighbor = float2(float(x), float(y));
            float2 point = hash2(i + neighbor);
            float2 diff = neighbor + point - f;
            float dist = length(diff);
            minDist = min(minDist, dist);
        }
    }
    
    return minDist;
}

// ============ 主滤镜函数 ============

fragment float4 crayonFilter(
    SingleInputVertexIO fragmentInput [[stage_in]],
    texture2d<float, access::sample> inputTexture [[texture(0)]],
    constant CrayonUniform& u [[buffer(1)]]
) {
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    
    float2 uv = fragmentInput.textureCoordinate;
    float2 texSize = float2(inputTexture.get_width(), inputTexture.get_height());
    float2 texel = 1.0 / texSize;
    
    // 采样中心颜色
    float4 centerColor = inputTexture.sample(s, uv);
    float3 color = centerColor.rgb;
    
    // === 1. 梯度计算（用于确定笔触方向和边缘检测） ===
    float gx = 0.0;
    float gy = 0.0;
    
    // Sobel算子
    float sobelX[3][3] = {
        {-1, 0, 1},
        {-2, 0, 2},
        {-1, 0, 1}
    };
    float sobelY[3][3] = {
        {-1, -2, -1},
        { 0,  0,  0},
        { 1,  2,  1}
    };
    
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 offset = float2(float(x), float(y)) * texel;
            float3 sampleColor = inputTexture.sample(s, uv + offset).rgb;
            float lum = getLuminance(sampleColor);
            gx += lum * sobelX[y + 1][x + 1];
            gy += lum * sobelY[y + 1][x + 1];
        }
    }
    
    float gradientMag = length(float2(gx, gy));
    float gradientAngle = atan2(gy, gx);
    
    // === 2. 颜色量化（模拟蜡笔的有限色阶） ===
    float levels = max(u.colorLevels, 4.0);
    float3 quantizedColor = floor(color * levels + 0.5) / levels;
    
    // 转换到HSV空间增强饱和度
    float3 hsv = rgbToHsv(quantizedColor);
    hsv.y = saturate(hsv.y * u.saturationBoost); // 增强饱和度
    hsv.z = pow(hsv.z, 0.95); // 轻微调整对比度
    
    // 添加一点暖色调（蜡笔通常偏暖）
    hsv.x = fract(hsv.x + 0.005);
    
    quantizedColor = hsvToRgb(hsv);
    
    // === 3. 方向性笔触纹理 ===
    float luminance = getLuminance(quantizedColor);
    
    // 笔触方向：垂直于梯度（沿着物体轮廓）
    float strokeAngle = gradientAngle + M_PI_F / 2.0;
    
    // 添加随机角度变化
    float angleNoise = (hash(uv * 100.0) - 0.5) * u.strokeAngleVar;
    strokeAngle += angleNoise;
    
    // 创建定向笔触纹理
    float2 strokeUV = uv * texSize / 10.0; // 缩放到合适的笔触密度
    strokeUV = rotate(strokeUV, strokeAngle);
    
    // 使用拉伸的噪声创建笔触效果
    float2 anisotropicUV = strokeUV * float2(u.strokeLength, 1.0) * u.strokeDensity;
    float strokePattern1 = smoothNoise(anisotropicUV);
    float strokePattern2 = smoothNoise(anisotropicUV * 2.3 + float2(100.0, 50.0));
    
    // 混合多层笔触以获得更自然的效果
    float strokeTexture = strokePattern1 * 0.6 + strokePattern2 * 0.4;
    
    // 在深色区域使用更多笔触（模拟用力涂抹）
    float strokeIntensity = 1.0 - luminance * 0.5;
    strokeTexture = mix(1.0, strokeTexture, strokeIntensity);
    
    // 添加Voronoi纹理增加笔触的不规则性
    float voronoi = voronoiNoise(strokeUV * u.strokeDensity * 0.5);
    strokeTexture *= mix(1.0, voronoi, 0.3);
    
    // 应用笔触纹理
    color = quantizedColor * mix(0.85, 1.0, strokeTexture);
    
    // === 4. 纸张纹理 ===
    // 细粒度噪声模拟纸张纹理
    float paperGrain = fractalNoise(uv * texSize * 0.8, 3);
    paperGrain = paperGrain * 0.5 + 0.5; // 归一化到 [0,1]
    
    // 在亮区域纸张纹理更明显（蜡笔覆盖少）
    float grainVisibility = u.paperGrainStrength * (0.2 + 0.8 * luminance);
    color = mix(color, color * mix(0.92, 1.08, paperGrain), grainVisibility);
    
    // === 5. 蜡质光泽效果 ===
    // 在高亮区域添加轻微的光泽
    float highlight = pow(saturate(luminance), 2.5);
    float3 glossColor = color + float3(0.05, 0.04, 0.02);
    color = mix(color, glossColor, highlight * u.waxGlossiness);
    
    // === 6. 边缘处理（手绘不规则边缘） ===
    // 检测边缘
    float edge = smoothstep(0.05, 0.25, gradientMag);
    
    // 添加边缘不规则性
    float edgeNoise = hash(uv * 500.0);
    edge = smoothstep(0.3 - edgeNoise * 0.2, 0.7 + edgeNoise * 0.2, edge);
    
    // 在边缘区域进行柔和混合（双边模糊效果）
    float3 blurredColor = float3(0.0);
    float totalWeight = 0.0;
    
    // 简化的双边模糊
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            if (x == 0 && y == 0) continue;
            
            float2 offset = float2(float(x), float(y)) * texel * 2.0;
            float3 sampleColor = inputTexture.sample(s, uv + offset).rgb;
            
            // 转换到HSV进行颜色相似度比较
            float3 sampleHSV = rgbToHsv(sampleColor);
            float3 centerHSV = rgbToHsv(centerColor.rgb);
            
            // 颜色相似度权重
            float colorDist = length(sampleHSV - centerHSV);
            float weight = exp(-colorDist * 5.0);
            
            blurredColor += sampleColor * weight;
            totalWeight += weight;
        }
    }
    
    if (totalWeight > 0.0) {
        blurredColor /= totalWeight;
        
        // 在边缘区域混合模糊颜色
        float3 blurredQuantized = floor(blurredColor * levels + 0.5) / levels;
        color = mix(color, blurredQuantized, edge * u.edgeStrength * 0.4);
    }
    
    // === 7. 边缘线条（深色轮廓） ===
    // 在强边缘添加深色线条（模拟蜡笔轮廓）
    float strongEdge = smoothstep(0.3, 0.6, gradientMag);
    float3 edgeColor = float3(0.15, 0.15, 0.2);
    
    // 边缘线条也要有不规则性
    float edgeLineNoise = smoothNoise(uv * texSize * 2.0);
    strongEdge *= mix(0.7, 1.0, edgeLineNoise);
    
    color = mix(color, edgeColor, strongEdge * u.edgeStrength);
    
    // === 8. 最终颜色调整 ===
    // 限制在合理范围内
    color = saturate(color);
    
    // 轻微增加整体亮度（蜡笔画通常比较明亮）
    color = pow(color, float3(0.95));
    
    return float4(color, centerColor.a);
}
