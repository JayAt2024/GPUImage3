import Foundation

/// 蜡笔画效果滤镜
/// 结合边缘检测、颜色量化和程序化纹理
public class CrayonOperation: BasicOperation {
    
    /// 边缘强度（建议范围：0.0-5.0）
    public var edgeStrength: Float = 2.0 {
        didSet {
            uniformSettings["edgeStrength"] = edgeStrength
        }
    }
    
    /// 颜色量化等级（建议范围：3-16）
    public var colorLevels: Float = 8.0 {
        didSet {
            uniformSettings["colorLevels"] = colorLevels
        }
    }
    
    /// 纹理强度（0.0-1.0）
    public var textureStrength: Float = 0.5 {
        didSet {
            uniformSettings["textureStrength"] = textureStrength
        }
    }
    
    public init() {
        super.init(fragmentFunctionName: "crayonFilter", numberOfInputs: 1)
        
        ({edgeStrength = 2.0})()
        ({colorLevels = 8.0})()
        ({textureStrength = 0.5})()
    }
}

/// 便捷的 GPUImageInput 扩展
extension ImageSource {
    
    @discardableResult
    public func crayon(edgeStrength: Float = 2.0, 
                      colorLevels: Float = 8.0,
                      textureStrength: Float = 0.5) -> CrayonOperation {
        let operation = CrayonOperation()
        operation.edgeStrength = edgeStrength
        operation.colorLevels = colorLevels
        operation.textureStrength = textureStrength
        self --> operation
        return operation
    }
}

// MARK: - 使用示例
/*
 
 // 基本用法
 let picture = PictureInput(image: myUIImage)
 let crayon = CrayonOperation()
 crayon.edgeStrength = 2.5     // 边缘强度
 crayon.colorLevels = 8.0      // 颜色量化等级
 crayon.textureStrength = 0.6  // 纹理强度（程序化噪声）
 
 let pictureOutput = PictureOutput()
 pictureOutput.imageAvailableCallback = { image in
     self.outputImage = image
 }
 
 picture --> crayon --> pictureOutput
 picture.processImage()
 
 // 或者使用便捷方法
 picture.crayon(
     edgeStrength: 2.5,
     colorLevels: 8.0,
     textureStrength: 0.6
 ) --> pictureOutput
 picture.processImage()
 
 // 参数说明：
 //
 // - edgeStrength: 边缘强度，建议 0.0-5.0
 //   - 0.0-1.0：轻微边缘
 //   - 2.0-3.0：明显的蜡笔轮廓
 //   - 4.0-5.0：非常强烈的边缘
 //
 // - colorLevels: 颜色量化等级，建议 3-16
 //   - 3-5：粗糙的色彩（类似儿童蜡笔画）
 //   - 6-10：适中的色彩层次（经典蜡笔效果）
 //   - 12-16：较为细腻的色彩过渡
 //
 // - textureStrength: 纹理强度，0.0-1.0
 //   - 0.0：无纹理效果
 //   - 0.3-0.5：轻微纸张质感
 //   - 0.6-1.0：明显的纸张颗粒感
 
 // 预设效果：
 
 // 1. 儿童蜡笔画风格
 crayon.edgeStrength = 3.0
 crayon.colorLevels = 5.0
 crayon.textureStrength = 0.7
 
 // 2. 精细蜡笔画风格
 crayon.edgeStrength = 1.5
 crayon.colorLevels = 12.0
 crayon.textureStrength = 0.4
 
 // 3. 粉笔画风格
 crayon.edgeStrength = 2.0
 crayon.colorLevels = 6.0
 crayon.textureStrength = 0.8
 
 */
