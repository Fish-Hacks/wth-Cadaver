//
//  SCNVector3.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 17/4/23.
//

import Foundation
import SceneKit

extension SCNVector3 {
    static func * (left: SCNVector3, right: Float) -> SCNVector3 {
        return SCNVector3Make(left.x * right, left.y * right, left.z * right)
    }
    
    static func + (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    func distance(to other: SCNVector3) -> CGFloat {
        return CGFloat(sqrt(pow(other.x - x, 2) + pow(other.y - y, 2) + pow(other.z - z, 2)))
    }
}
