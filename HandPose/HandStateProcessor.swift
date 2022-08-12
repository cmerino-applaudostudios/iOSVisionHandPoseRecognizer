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
    case nothing
    
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
        case .nothing:
            return ""
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
    
    var isMiddleFingerExtended: Bool {
        middleState == .extended
    }
    
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
        switch (thumbState, indexState, middleState, ringState, littleState) {
        case (.extended, .extended, .extended, .extended, .extended):
            return .openHand
        case (.close, .close, .close, .close, .close):
            return .fist
        case (.extended, .extended, .close, .close, .extended):
            return .loveYouGesture
        case (.close, .extended, .close, .close, .extended):
            return .signOfHornGesture
        case (.close, .extended, .extended, .close, .close):
            return .victoryHand
        case (.extended, .close, .close, .close, .extended):
            return .callMeHand
        case (.close, .extended, .close, .close, .close):
            return .indexPointing
        default:
            return .nothing
        }
    }
    
    func getFingerState(tipPoint: CGPoint?, palmArea: [CGPoint]) -> FingerPositionState {
        guard let tipPoint = tipPoint else {
            return .extended
        }
        
        return tipPoint.isInsidePolygon(vertices: palmArea) ? .close : .extended
    }
}
