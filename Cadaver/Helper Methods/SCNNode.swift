//
//  SCNNode.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 18/4/23.
//

import Foundation
import SceneKit

extension SCNNode {
    func contains(_ point: SCNVector3) -> Bool {
        return boundingBox.min.x...boundingBox.max.x ~= point.x && boundingBox.min.y...boundingBox.max.y ~= point.y && boundingBox.min.z...boundingBox.max.z ~= point.z
    }
}
