import Foundation
import Metal

/// 蜡笔滤镜操作
/// 将图像转换为逼真的蜡笔画效果
public class CrayonOperation: BasicOperation {
  
  // MARK: - 公开属性
  
  /// 笔触长度 (0.5 - 2.0)
  /// 控制蜡笔笔触的长度
  public var strokeLength: Float = 1.0 {
    didSet {
      uniformSettings["strokeLength"] = strokeLength
    }
  }
  
  /// 笔触密度 (3.0 - 8.0)
  /// 控制笔触的细密程度
  public var strokeDensity: Float = 5.0 {
    didSet {
      uniformSettings["strokeDensity"] = strokeDensity
    }
  }
  
  /// 纸张纹理强度 (0.1 - 0.5)
  /// 控制纸张颗粒感的可见度
  public var paperGrainStrength: Float = 0.25 {
    didSet {
      uniformSettings["paperGrainStrength"] = paperGrainStrength
    }
  }
  
  /// 饱和度增强 (1.1 - 1.4)
  /// 控制色彩的鲜艳程度
  public var saturationBoost: Float = 1.25 {
    didSet {
      uniformSettings["saturationBoost"] = saturationBoost
    }
  }
  
  /// 边缘强度 (0.3 - 0.8)
  /// 控制边缘和轮廓的明显程度
  public var edgeStrength: Float = 0.5 {
    didSet {
      uniformSettings["edgeStrength"] = edgeStrength
    }
  }
  
  /// 颜色量化级别 (6 - 12)
  /// 控制色阶的数量
  public var colorLevels: Float = 8.0 {
    didSet {
      uniformSettings["colorLevels"] = colorLevels
    }
  }
  
  /// 蜡质光泽度 (0.1 - 0.4)
  /// 控制高光区域的光泽感
  public var waxGlossiness: Float = 0.2 {
    didSet {
      uniformSettings["waxGlossiness"] = waxGlossiness
    }
  }
  
  /// 笔触角度变化 (0.0 - 0.3)
  /// 控制笔触方向的随机性
  public var strokeAngleVar: Float = 0.15 {
    didSet {
      uniformSettings["strokeAngleVar"] = strokeAngleVar
    }
  }
  
  // MARK: - 初始化
  
  /// 使用默认参数初始化蜡笔滤镜
  public init() {
    super.init(fragmentFunctionName: "crayonFilter", numberOfInputs: 1)
    
    // 设置初始 uniform 值
    uniformSettings["strokeLength"] = strokeLength
    uniformSettings["strokeDensity"] = strokeDensity
    uniformSettings["paperGrainStrength"] = paperGrainStrength
    uniformSettings["saturationBoost"] = saturationBoost
    uniformSettings["edgeStrength"] = edgeStrength
    uniformSettings["colorLevels"] = colorLevels
    uniformSettings["waxGlossiness"] = waxGlossiness
    uniformSettings["strokeAngleVar"] = strokeAngleVar
  }
  
  /// 应用轻柔素描风格预设
  public func applyLightSketchPreset() {
    strokeLength = 0.7
    strokeDensity = 4.0
    paperGrainStrength = 0.35
    saturationBoost = 1.15
    edgeStrength = 0.3
    colorLevels = 10.0
    waxGlossiness = 0.15
    strokeAngleVar = 0.2
  }
  
  /// 应用浓重涂抹风格预设
  public func applyHeavyShadingPreset() {
    strokeLength = 1.5
    strokeDensity = 6.5
    paperGrainStrength = 0.15
    saturationBoost = 1.35
    edgeStrength = 0.7
    colorLevels = 6.0
    waxGlossiness = 0.3
    strokeAngleVar = 0.1
  }
  
  /// 应用彩色铅笔风格预设
  public func applyColoredPencilPreset() {
    strokeLength = 0.5
    strokeDensity = 7.0
    paperGrainStrength = 0.4
    saturationBoost = 1.1
    edgeStrength = 0.6
    colorLevels = 12.0
    waxGlossiness = 0.1
    strokeAngleVar = 0.25
  }
  
  /// 应用经典蜡笔风格预设（默认设置）
  public func applyClassicCrayonPreset() {
    strokeLength = 1.0
    strokeDensity = 5.0
    paperGrainStrength = 0.25
    saturationBoost = 1.25
    edgeStrength = 0.5
    colorLevels = 8.0
    waxGlossiness = 0.2
    strokeAngleVar = 0.15
  }
  
  /// 应用柔和粉彩风格预设
  public func applySoftPastelPreset() {
    strokeLength = 1.2
    strokeDensity = 4.5
    paperGrainStrength = 0.3
    saturationBoost = 1.15
    edgeStrength = 0.35
    colorLevels = 9.0
    waxGlossiness = 0.25
    strokeAngleVar = 0.18
  }
  
  /// 应用儿童蜡笔风格预设
  public func applyKidsCrayonPreset() {
    strokeLength = 1.5
    strokeDensity = 4.0
    paperGrainStrength = 0.2
    saturationBoost = 1.4
    edgeStrength = 0.4
    colorLevels = 6.0
    waxGlossiness = 0.3
    strokeAngleVar = 0.2
  }
}
