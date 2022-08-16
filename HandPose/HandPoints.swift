//
//  HandPoints.swift
//  HandPose
//
//  Created by Carlos Merino on 11/7/22.
//  Copyright © 2022 Carlos Merino. All rights reserved.
//

import Foundation
import UIKit
import Vision
import AVFoundation

enum FingerName: String {
    case index, middle, ring, little, thumb
    
    var vnJointName: [VNHumanHandPoseObservation.JointName] {
        switch self {
        case .index:
            return [.indexTip, .indexMCP, .indexPIP, .indexDIP]
        case .middle:
            return [.middleTip, .middleMCP, .middlePIP, .middleDIP]
        case .ring:
            return [.ringTip, .ringMCP, .ringPIP, .ringDIP]
        case .little:
            return [.littleTip, .littleMCP, .littlePIP, .littleDIP]
        case .thumb:
            return [.thumbTip, .thumbCMC, .thumbMP, .thumbIP]
        }
    }
}

struct AVFoundationPoint {
    var point: CGPoint
}

extension AVFoundationPoint {
    init(with recognizedPoint: VNRecognizedPoint?) {
        guard let recognizedPoint = recognizedPoint, recognizedPoint.confidence > 0.3 else {
            self.point = .init(x: 0, y: 0)
            return
        }

        self.point = .init(x: recognizedPoint.location.x, y: recognizedPoint.location.y)
    }
}

struct FingerPoints {
    var fingerName: FingerName
    var tipPoint: CGPoint?
    var mcpPoint: CGPoint?
    var pipPoint: CGPoint?
    var dipPoint: CGPoint?
    
    func getAllFingerPoints() -> [CGPoint] {
        return [tipPoint, mcpPoint, pipPoint, dipPoint].compactMap{ $0 }
    }
}

struct HandArea {
    var thumbFinger: CGPoint?
    var middleFinger: CGPoint?
    var littleFinger: CGPoint?
    var wrist: CGPoint?
    
    func getArrayPoints() -> [CGPoint?] {
        [thumbFinger, middleFinger, littleFinger, wrist]
    }
}

extension FingerPoints {
    init(with recognizedPoints: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint],
         translatedToLayer layer: AVCaptureVideoPreviewLayer, fingerName: FingerName) {
        self.fingerName = fingerName
        let tip = layer.layerPointConverted(fromCaptureDevicePoint: AVFoundationPoint(with: recognizedPoints[fingerName.vnJointName[0]]).point)
        let mcp = layer.layerPointConverted(fromCaptureDevicePoint: AVFoundationPoint(with: recognizedPoints[fingerName.vnJointName[1]]).point)
        let pip = layer.layerPointConverted(fromCaptureDevicePoint: AVFoundationPoint(with: recognizedPoints[fingerName.vnJointName[2]]).point)
        let dip = layer.layerPointConverted(fromCaptureDevicePoint: AVFoundationPoint(with: recognizedPoints[fingerName.vnJointName[3]]).point)
        self.tipPoint = tip == .zero ? nil : tip
        self.mcpPoint = mcp == .zero ? nil : mcp
        self.pipPoint = pip == .zero ? nil : pip
        self.dipPoint = dip == .zero ? nil : dip
    }
}

struct WristPoint {
    var point: CGPoint?
}

extension WristPoint {
    init(with recognizedPoint: VNRecognizedPoint, translatedToLayer layer: AVCaptureVideoPreviewLayer) {
        self.point = layer.layerPointConverted(fromCaptureDevicePoint: AVFoundationPoint(with: recognizedPoint).point)
    }
}

struct HandPointsBuilder {
    var thumbFinger: FingerPoints?
    var indexFinger: FingerPoints?
    var middleFinger: FingerPoints?
    var ringFinger: FingerPoints?
    var littleFinger: FingerPoints?
    var wrist: WristPoint?
    
    var handTotalHeight: CGFloat {
        guard let wristY = wrist?.point?.y, let middleFingerY = middleFinger?.tipPoint?.y, let middleFingerMCY = middleFinger?.mcpPoint?.y else {
            return 0.0
        }
        
        return CGFloat(abs(Float(middleFingerY - middleFingerMCY)) + abs(Float(middleFingerMCY - wristY)))
    }
    
    var handTotalWidth: CGFloat {
        guard let littleFingerMCX = littleFinger?.mcpPoint?.x, let littleFingerTipX = littleFinger?.tipPoint?.x,
              let thumbFingerMCX = thumbFinger?.mcpPoint?.x, let thumbFingerTipX = thumbFinger?.tipPoint?.x else {
            return 0.0
        }
        
        return CGFloat(abs(Float(littleFingerTipX - littleFingerMCX)) +
                       abs(Float(littleFingerMCX - thumbFingerMCX)) +
                       abs(Float(thumbFingerMCX - thumbFingerTipX)))
    }
    
    var handYPoint: CGFloat {
        let tipPoints: [CGFloat] = [indexFinger?.tipPoint?.y, middleFinger?.tipPoint?.y, ringFinger?.tipPoint?.y, littleFinger?.tipPoint?.y]
            .compactMap { $0 }
        
        return tipPoints.min() ?? 0.0
    }
    
    var shouldUpdateHeight: Bool {
        middleFinger?.tipPoint?.isPointNearOf(points: [middleFinger?.mcpPoint, middleFinger?.dipPoint].compactMap { $0 }) ?? false
    }
    
    var shouldUpdateWidth: Bool {
        return !(thumbFinger?.tipPoint?.isPointNearOf(points: getFingerPoints()) ?? false) &&
        (littleFinger?.tipPoint?.isPointNearOf(points: [littleFinger?.mcpPoint, littleFinger?.dipPoint].compactMap {$0}) ?? false)
    }
    
    func getAllHandPoints() -> [CGPoint] {
        var points: [CGPoint] = []
        
        points.append(contentsOf: thumbFinger?.getAllFingerPoints() ?? [])
        points.append(contentsOf: indexFinger?.getAllFingerPoints() ?? [])
        points.append(contentsOf: middleFinger?.getAllFingerPoints() ?? [])
        points.append(contentsOf: ringFinger?.getAllFingerPoints() ?? [])
        points.append(contentsOf: littleFinger?.getAllFingerPoints() ?? [])
        if let wristPoint = wrist?.point {
            points.append(wristPoint)
        }
        
        return points
    }
    
    func getPalmArea() -> [CGPoint] {
        var points: [CGPoint?] = []
        
        points.append(contentsOf: [ indexFinger?.pipPoint,
                                    middleFinger?.pipPoint,
                                    ringFinger?.pipPoint,
                                    littleFinger?.pipPoint,
                                    thumbFinger?.mcpPoint,
                                    thumbFinger?.pipPoint,
                                    wrist?.point
        ])
        
        return points.compactMap { $0 }
    }
    
    func getHandArea() -> HandArea {
        return HandArea(thumbFinger: thumbFinger?.mcpPoint,
                        middleFinger: middleFinger?.mcpPoint,
                        littleFinger: littleFinger?.mcpPoint,
                        wrist: wrist?.point)
    }
    
    func getFingerPoints() -> [CGPoint] {
        var points: [CGPoint] = []
        
        points.append(contentsOf: indexFinger?.getAllFingerPoints() ?? [])
        points.append(contentsOf: middleFinger?.getAllFingerPoints() ?? [])
        points.append(contentsOf: ringFinger?.getAllFingerPoints() ?? [])
        points.append(contentsOf: littleFinger?.getAllFingerPoints() ?? [])
        
        return points
    }
}

extension HandPointsBuilder {
    init(with recoginizedRequest: VNHumanHandPoseObservation, translateTo layer: AVCaptureVideoPreviewLayer) {
        self.thumbFinger = try? .init(with: recoginizedRequest.recognizedPoints(.thumb),
                                      translatedToLayer: layer, fingerName: .thumb)
        self.indexFinger = try? .init(with: recoginizedRequest.recognizedPoints(.indexFinger),
                                      translatedToLayer: layer, fingerName: .index)
        self.middleFinger = try? .init(with: recoginizedRequest.recognizedPoints(.middleFinger),
                                       translatedToLayer: layer, fingerName: .middle)
        self.ringFinger = try? .init(with: recoginizedRequest.recognizedPoints(.ringFinger),
                                     translatedToLayer: layer, fingerName: .ring)
        self.littleFinger = try? .init(with: recoginizedRequest.recognizedPoints(.littleFinger),
                                       translatedToLayer: layer, fingerName: .little)
        self.wrist = try? .init(with: recoginizedRequest.recognizedPoint(.wrist),
                                translatedToLayer: layer)
    }
}
