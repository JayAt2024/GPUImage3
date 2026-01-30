//
//  ColorUtils.h
//  FlowsPro
//
//  Created by jay on 1/30/26.
//

#ifndef ColorUtils_h
#define ColorUtils_h

#include <metal_stdlib>
using namespace metal;

// RGB 转 HSV
inline float3 rgbToHsv(float3 rgb) {
  float maxVal = max(max(rgb.r, rgb.g), rgb.b);
  float minVal = min(min(rgb.r, rgb.g), rgb.b);
  float delta = maxVal - minVal;
  
  float h = 0.0;
  float s = (maxVal > 0.0) ? (delta / maxVal) : 0.0;
  float v = maxVal;
  
  if (delta > 0.0) {
    if (maxVal == rgb.r) {
      h = (rgb.g - rgb.b) / delta + (rgb.g < rgb.b ? 6.0 : 0.0);
    } else if (maxVal == rgb.g) {
      h = (rgb.b - rgb.r) / delta + 2.0;
    } else {
      h = (rgb.r - rgb.g) / delta + 4.0;
    }
    h /= 6.0;
  }
  
  return float3(h, s, v);
}

// HSV 转 RGB
inline float3 hsvToRgb(float3 hsv) {
  float h = hsv.x * 6.0;
  float s = hsv.y;
  float v = hsv.z;
  
  float c = v * s;
  float x = c * (1.0 - abs(fmod(h, 2.0) - 1.0));
  float m = v - c;
  
  float3 rgb;
  if (h < 1.0) rgb = float3(c, x, 0.0);
  else if (h < 2.0) rgb = float3(x, c, 0.0);
  else if (h < 3.0) rgb = float3(0.0, c, x);
  else if (h < 4.0) rgb = float3(0.0, x, c);
  else if (h < 5.0) rgb = float3(x, 0.0, c);
  else rgb = float3(c, 0.0, x);
  
  return rgb + float3(m);
}

#endif /* ColorUtils_h */
