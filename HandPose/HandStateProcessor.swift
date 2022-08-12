//
//  HandStateProcessor.swift
//  HandPose
//
//  Created by Carlos Merino on 2/8/22.
//  Copyright © 2022 Carlos Merino. All rights reserved.
//

import Foundation
import Combine
import UIKit

enum FingerPositionState {
    case close
    case extended
    
    var isExtended: Bool {
        return self == .extended
    }
    
    var isClose: Bool {
        return self == .close
    }
}

enum HandPose {
    case openHand
    case victoryHand
    case loveYouGesture
    case signOfHornGesture
    case callMeHand
    case indexPointing
    case fist
    
    var stringEmoji: String {
        switch self {
        case .openHand:
            return "✋"
        case .victoryHand:
            return "✌️"
        case .loveYouGesture:
            return "🤟"
        case .signOfHornGesture:
            return "🤘"
        case .callMeHand:
            return "🤙"
        case .indexPointing:
            return "☝️"
        case .fist:
            return "✊"
        }
    }
}

class HandStateProcessor: CustomStringConvertible {
    var description: String {
        "Index: \(indexState), middle \(middleState), ring \(ringState), little \(littleState), thumb \(thumbState)"
    }
    
    var indexState: FingerPositionState
    var middleState: FingerPositionState
    var ringState: FingerPositionState
    var littleState: FingerPositionState
    var thumbState: FingerPositionState
    
    var handStateResult: PassthroughSubject<HandPose, Never> = .init()
    
    init() {
        self.indexState = .close
        self.middleState = .close
        self.ringState = .close
        self.littleState = .close
        self.thumbState = .close
    }
    
    func updatePoints(handPoints: HandPointsBuilder) {
        self.indexState = getFingerState(tipPoint: handPoints.indexFinger?.tipPoint, palmArea: handPoints.getPalmArea())
        self.middleState = getFingerState(tipPoint: handPoints.middleFinger?.tipPoint, palmArea: handPoints.getPalmArea())
        self.ringState = getFingerState(tipPoint: handPoints.ringFinger?.tipPoint, palmArea: handPoints.getPalmArea())
        self.littleState = getFingerState(tipPoint: handPoints.littleFinger?.tipPoint, palmArea: handPoints.getPalmArea())
        self.thumbState = getFingerState(tipPoint: handPoints.thumbFinger?.tipPoint, palmArea: handPoints.getPalmArea())
        self.handStateResult.send(getHandPose())
    }
    
    func getHandPose() -> HandPose {
        if indexState.isClose && middleState.isClose && ringState.isClose && littleState.isClose && thumbState.isClose {
            return .fist
        } else if thumbState.isExtended && indexState.isExtended && middleState.isClose && ringState.isClose && littleState.isExtended {
            return .loveYouGesture
        } else if thumbState.isClose && indexState.isExtended && middleState.isExtended && ringState.isClose && littleState.isClose {
            return .victoryHand
        } else if thumbState.isClose && indexState.isExtended && middleState.isClose && ringState.isClose && littleState.isExtended {
            return .signOfHornGesture
        } else if thumbState.isExtended && indexState.isClose && middleState.isClose && ringState.isClose && littleState.isExtended {
            return .callMeHand
        } else if thumbState.isClose && indexState.isExtended && middleState.isClose && ringState.isClose && littleState.isClose {
            return .indexPointing
        }
        return .openHand
    }
    
    func getFingerState(tipPoint: CGPoint?, palmArea: [CGPoint]) -> FingerPositionState {
        guard let tipPoint = tipPoint else {
            return .extended
        }
        
        return tipPoint.isInsidePolygon(vertices: palmArea) ? .close : .extended
    }
}
