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

extension FingerPoints {
    init(with recognizedPoints: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint],
         translatedToLayer layer: AVCaptureVideoPreviewLayer, fingerName: FingerName) {
        self.fingerName = fingerName
        let keys = Array(recognizedPoints.keys)
        let tip = layer.layerPointConverted(fromCaptureDevicePoint: AVFoundationPoint(with: recognizedPoints[keys[0]]).point)
        let mcp = layer.layerPointConverted(fromCaptureDevicePoint: AVFoundationPoint(with: recognizedPoints[keys[1]]).point)
        let pip = layer.layerPointConverted(fromCaptureDevicePoint: AVFoundationPoint(with: recognizedPoints[keys[2]]).point)
        let dip = layer.layerPointConverted(fromCaptureDevicePoint: AVFoundationPoint(with: recognizedPoints[keys[3]]).point)
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
