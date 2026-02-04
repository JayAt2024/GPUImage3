//
//  SkinProtectFilter.swift
//  GPUImage
//
//  Created by jay on 2/4/26.
//


import Foundation
import Metal

public class SkinProtectFilter: BasicOperation {
    
    // MARK: - 可调节参数
    public var skinLift: Float = 0.04 {
        didSet {
            uniformSettings["skinLift"] = skinLift
        }
    }
    
    public var skinBlueReduce: Float = 0.03 {
        didSet {
            uniformSettings["skinBlueReduce"] = skinBlueReduce
        }
    }
    
    // MARK: - 初始化
    public init() {
        super.init(fragmentFunctionName: "skinProtectFragment",
                   numberOfInputs: 1)
        
        ({ skinLift = 0.04 })()
        ({ skinBlueReduce = 0.03 })()
    }
}
