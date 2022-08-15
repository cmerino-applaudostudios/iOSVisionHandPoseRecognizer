/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The camera view shows the feed from the camera, and renders the points
     returned from VNDetectHumanHandpose observations.
*/

import UIKit
import AVFoundation

class CameraView: UIView {

    private var overlayLayer = CAShapeLayer()
    private var pointsPath = UIBezierPath()
    private var detectionOverlay = CAShapeLayer()
    private var previousHandFrame = CGRect()
    private var handWidth: CGFloat = 0
    private var handHeight: CGFloat = 0
    private var yMiddleFinger: CGFloat = 0
    private var isShowingEmoji: Bool = false

    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer == previewLayer {
            overlayLayer.frame = layer.bounds
        }
    }

    private func setupOverlay() {
        previewLayer.addSublayer(overlayLayer)
        previewLayer.addSublayer(detectionOverlay)
    }
    
    func showEmojiIf(switchIsActive: Bool) {
        isShowingEmoji = switchIsActive
    }
    
    func showPoints(_ points: [CGPoint], color: UIColor) {
        pointsPath.removeAllPoints()
        for point in points {
            pointsPath.move(to: point)
            pointsPath.addArc(withCenter: point, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        overlayLayer.fillColor = color.cgColor
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlayLayer.path = pointsPath.cgPath
        CATransaction.commit()
    }
    
    func showHandArea(_ points: HandArea, color: UIColor, emoji: HandPose, updateAreaSize: Bool, mustChangeWidth: Bool) {
        CATransaction.begin()
        detectionOverlay.sublayers = nil
        let totalHeight = (points.middleFinger?.y ?? 0) - ((points.middleFinger?.y ?? 0) * 0.3)
        let totalWidth = (points.thumbFinger?.x ?? 0) + ((points.thumbFinger?.x ?? 0) * 0.3)
        handWidth = mustChangeWidth ? CGFloat(abs(Int(totalWidth) - Int(points.littleFinger?.x ?? 0))) : handWidth
        handHeight =  updateAreaSize ? CGFloat(abs(Int(points.wrist?.y ?? 0) - Int(totalHeight))) : handHeight
        let xShapeLayer = Int(points.thumbFinger?.x ?? 0) > Int(points.littleFinger?.x ?? 0) ? points.littleFinger?.x : points.thumbFinger?.x
        yMiddleFinger = updateAreaSize ? totalHeight : yMiddleFinger
        let shapeLayer = createTextLayer(CGRect(x: xShapeLayer ?? 0, y: yMiddleFinger, width: handWidth, height: handHeight), with: emoji, updateAreaSize: updateAreaSize)
        if isShowingEmoji {
            detectionOverlay.addSublayer(shapeLayer)
        }
        CATransaction.commit()
    }
    
    // This fuction create the text layer that contains the emoji
    func createTextLayer(_ bounds: CGRect, with emoji: HandPose, updateAreaSize: Bool) -> CATextLayer {
        let shapeLayer = CATextLayer()
        let emojiRect = updateAreaSize ? CGRect(origin: CGPoint(x: bounds.origin.x, y: bounds.origin.y - 50), size: CGSize(width: bounds.size.width, height: bounds.size.height + 50)) : previousHandFrame
        shapeLayer.string = emoji.stringEmoji
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.fontSize = emojiRect.size.width
        print(updateAreaSize.description)
        shapeLayer.frame = emojiRect
        previousHandFrame = shapeLayer.frame
        return shapeLayer
    }
}
