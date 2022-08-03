//
//  HandStateProcessor.swift
//  HandPose
//
//  Created by Carlos Merino on 2/8/22.
//  Copyright © 2022 Carlos Merino. All rights reserved.
//

import Foundation
import UIKit

enum FingerPositionState {
    case close
    case extended
}

struct HandStateProcessor: CustomStringConvertible {
    var description: String {
        "Index: \(indexState), middle \(middleState), ring \(ringState), little \(littleState), thumb \(thumbState)"
    }
    
    var indexState: FingerPositionState
    var middleState: FingerPositionState
    var ringState: FingerPositionState
    var littleState: FingerPositionState
    var thumbState: FingerPositionState
    
    init(handPoints: HandPointsBuilder) {
        self.indexState = getFingerState(tipPoint: handPoints.indexFinger?.tipPoint, palmArea: handPoints.getPalmArea())
        self.middleState = getFingerState(tipPoint: handPoints.middleFinger?.tipPoint, palmArea: handPoints.getPalmArea())
        self.ringState = getFingerState(tipPoint: handPoints.ringFinger?.tipPoint, palmArea: handPoints.getPalmArea())
        self.littleState = getFingerState(tipPoint: handPoints.littleFinger?.tipPoint, palmArea: handPoints.getPalmArea())
        self.thumbState = getFingerState(tipPoint: handPoints.thumbFinger?.tipPoint, palmArea: handPoints.getPalmArea())
    }
}

func getFingerState(tipPoint: CGPoint?, palmArea: [CGPoint]) -> FingerPositionState {
    guard let tipPoint = tipPoint else {
        return .extended
    }
    
    return tipPoint.isPointInsideOf(polygon: palmArea) ? .close : .extended
}
