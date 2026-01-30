import Foundation

/// 油画效果滤镜
/// 使用 Kuwahara 滤波器创建油画笔触效果
public class OilPaintingOperation: BasicOperation {
    
    /// 笔刷大小（建议范围：3-15）
    public var brushSize: Float = 7.0 {
        didSet {
            uniformSettings["brushSize"] = brushSize
        }
    }
    
    /// 效果强度（0.0-1.0）
    public var intensity: Float = 0.8 {
        didSet {
            uniformSettings["intensity"] = intensity
        }
    }
    
    public init() {
        super.init(fragmentFunctionName: "oilPaintingFilter", numberOfInputs: 1)
        
        ({brushSize = 7.0})()
        ({intensity = 0.8})()
    }
}

/// 便捷的 GPUImageInput 扩展
extension ImageSource {
    
    @discardableResult
    public func oilPainting(brushSize: Float = 7.0, intensity: Float = 0.8) -> OilPaintingOperation {
        let operation = OilPaintingOperation()
        operation.brushSize = brushSize
        operation.intensity = intensity
        self --> operation
        return operation
    }
}

// MARK: - 使用示例
/*
 
 // 基本用法
 let picture = PictureInput(image: myUIImage)
 let oilPainting = OilPaintingOperation()
 oilPainting.brushSize = 10.0  // 笔刷大小，越大越模糊
 oilPainting.intensity = 0.9   // 效果强度
 
 let pictureOutput = PictureOutput()
 pictureOutput.imageAvailableCallback = { image in
     // 处理输出图片
     self.outputImage = image
 }
 
 picture --> oilPainting --> pictureOutput
 picture.processImage()
 
 // 或者使用便捷方法
 picture.oilPainting(brushSize: 10.0, intensity: 0.9) --> pictureOutput
 picture.processImage()
 
 // 参数说明：
 // - brushSize: 笔刷大小，建议 3-15
 //   - 较小值（3-5）：细腻的油画效果
 //   - 中等值（7-10）：经典油画效果
 //   - 较大值（12-15）：粗犷的油画效果
 //
 // - intensity: 效果强度，0.0-1.0
 //   - 0.0：原图
 //   - 0.5：轻微油画效果
 //   - 0.8-1.0：完全油画效果
 
 */
