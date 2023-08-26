//
//  CGPoint.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 17/4/23.
//

import Foundation

extension CGPoint {
    static func midpoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
    
    func distance(from point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }
}
