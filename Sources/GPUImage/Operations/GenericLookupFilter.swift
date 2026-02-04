//
//  File.swift
//  GPUImage
//
//  Created by jay on 2/4/26.
//

import Foundation

public class GenericLookupFilter: BasicOperation {
  public var lutSize: Float = 8.0 { didSet { uniformSettings["lutSize"] = lutSize } }
  public var intensity: Float = 1.0 { didSet { uniformSettings["intensity"] = intensity } }
  public var lookupImage: PictureInput? {  // TODO: Check for retain cycles in all cases here
    didSet {
      lookupImage?.addTarget(self, atTargetIndex: 1)
      lookupImage?.processImage()
    }
  }
  
  public init() {
    super.init(fragmentFunctionName: "lookupFragment", numberOfInputs: 2)
    
    ({ intensity = 1.0 })()
  }
}
