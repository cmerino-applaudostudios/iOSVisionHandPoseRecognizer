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
    
    func showHandArea(_ points: HandArea, color: UIColor, emoji: String) {
        CATransaction.begin()
        detectionOverlay.sublayers = nil
        let widthLayer = abs(Int(points.thumbFinger?.x ?? 0) - Int(points.littleFinger?.x ?? 0))
        let heightLayer = abs(Int(points.thumbFinger?.x ?? 0) - Int(points.littleFinger?.x ?? 0))
        let xShapeLayer = Int(points.thumbFinger?.x ?? 0) > Int(points.littleFinger?.x ?? 0) ? points.littleFinger?.x : points.thumbFinger?.x
        let shapeLayer = createTextLayer(CGRect(x: xShapeLayer ?? 0, y: points.middleFinger?.y ?? 0, width: CGFloat(widthLayer), height: CGFloat(heightLayer)), with: emoji)
        detectionOverlay.addSublayer(shapeLayer)
        CATransaction.commit()
    }
    
    // This fuction create the rectangle
    func createRoundedRectLayer(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Detected Hand"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    
    // This fuction create the text layer that contains the emoji
    func createTextLayer(_ bounds: CGRect, with emoji: String) -> CATextLayer {
        let shapeLayer = CATextLayer()
        let emojiRect = CGRect(origin: CGPoint(x: bounds.origin.x, y: bounds.origin.y - 50), size: CGSize(width: bounds.size.width, height: bounds.size.height + 50))
        shapeLayer.string = emoji
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.fontSize = bounds.size.width
        shapeLayer.frame = emojiRect
        return shapeLayer
    }
}
