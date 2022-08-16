//
//  CGPoint+Extension.swift
//  HandPose
//
//  Created by Carlos Merino on 15/8/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import UIKit

// MARK: - CGPoint helpers

extension CGPoint {
    
    static func midPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
    
    func distance(from point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }
    
    func isPointInsideOf(polygon: [CGPoint]) -> Bool {
        if polygon.count <= 1 {
            return false
        }
        
        let p = UIBezierPath()
        let firstPoint = polygon[0] as CGPoint
        
        p.move(to: firstPoint)
        
        for index in 1...polygon.count-1 {
            p.addLine(to: polygon[index] as CGPoint)
        }
        
        p.close()
        
        return p.contains(self)
    }
    
    func isInsidePolygon(vertices: [CGPoint]) -> Bool {
        guard vertices.count > 0 else { return false }
        
        var i = 0, j = vertices.count - 1, c = false, vi: CGPoint, vj: CGPoint
        while true {
            guard i < vertices.count else { break }
            vi = vertices[i]
            vj = vertices[j]
            if (vi.y > y) != (vj.y > y) &&
                x < (vj.x - vi.x) * (y - vi.y) / (vj.y - vi.y) + vi.x {
                c = !c
            }
            j = i
            i += 1
        }
        return c
    }
    
    func isPointNearOf(points: [CGPoint], minimunDistance: CGFloat = 40.0) -> Bool {
        var isClose = false
        
        for index in 0..<points.count {
            if self.distance(from: points[index]) < minimunDistance {
                isClose = true
                break
            }
        }
        
        return isClose
    }
}
