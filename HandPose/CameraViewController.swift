/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The app's main view controller object.
 */

import UIKit
import AVFoundation
import Vision
import Combine

class CameraViewController: UIViewController {
    
    private var cameraView: CameraView { view as! CameraView }
    private var showEmojiSwitchView = UISwitch()
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private var handPose: HandPose = .openHand
    
    private let handStateProcessor = HandStateProcessor()
    private let drawOverlay = CAShapeLayer()
    private let drawPath = UIBezierPath()
    private var evidenceBuffer = [HandGestureProcessor.PointsPair]()
    private var lastDrawPoint: CGPoint?
    private var isFirstSegment = true
    private var lastObservationTimestamp = Date()
    private var cancellables: Set<AnyCancellable> = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drawOverlay.frame = view.layer.bounds
        drawOverlay.lineWidth = 5
        drawOverlay.strokeColor = #colorLiteral(red: 0.6, green: 0.1, blue: 0.3, alpha: 1).cgColor
        drawOverlay.fillColor = #colorLiteral(red: 0.9999018312, green: 1, blue: 0.9998798966, alpha: 0).cgColor
        view.layer.addSublayer(drawOverlay)
        handPoseRequest.maximumHandCount = 1
        bindProcessor()
        setUpSwitch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            if cameraFeedSession == nil {
                cameraView.previewLayer.videoGravity = .resizeAspectFill
                try setupAVSession()
                cameraView.previewLayer.session = cameraFeedSession
            }
            cameraFeedSession?.startRunning()
        } catch {
            AppError.display(error, inViewController: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraFeedSession?.stopRunning()
        super.viewWillDisappear(animated)
    }
    
    private func bindProcessor() {
        handStateProcessor.handStateResult
            .throttle(for: 0.2, scheduler: RunLoop.main, latest: true)
            .sink(receiveValue: { [weak self] value in
                self?.handPose = value
                // Debug
                print("\(value.stringEmoji)")
            }).store(in: &cancellables)
    }
    
    private func setUpSwitch() {
        showEmojiSwitchView.setOn(false, animated: true)
        showEmojiSwitchView.addTarget(self, action: #selector(updateSwitch), for: .valueChanged)
        showEmojiSwitchView.frame = CGRect(x: 40, y: 60, width: 50, height: 50)
        
        self.view.addSubview(showEmojiSwitchView)
    }
    
    @objc func updateSwitch() {
        cameraView.showEmojiIf(switchIsActive: showEmojiSwitchView.isOn)
    }
    
    func setupAVSession() throws {
        // Select a front facing camera, make an input.
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw AppError.captureSessionSetup(reason: "Could not find a front facing camera.")
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw AppError.captureSessionSetup(reason: "Could not create video device input.")
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Add a video input.
        guard session.canAddInput(deviceInput) else {
            throw AppError.captureSessionSetup(reason: "Could not add video device input to the session")
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            // Add a video data output.
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            throw AppError.captureSessionSetup(reason: "Could not add video data output to the session")
        }
        session.commitConfiguration()
        cameraFeedSession = session
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .downMirrored, options: [:])

        do {
            try handler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                return
            }
            
            DispatchQueue.main.sync {
                let previewLayer = cameraView.previewLayer
                let handPoints = HandPointsBuilder(with: observation, translateTo: previewLayer)
                self.handStateProcessor.updatePoints(handPoints: handPoints)
                self.cameraView.showPoints(handPoints.getAllHandPoints(), color: .green)
                self.cameraView.showHandArea(handPoints.getHandArea(),
                                             color: .red,
                                             emoji: self.handPose,
                                             updateAreaSize: self.handStateProcessor.isMiddleFingerExtended,
                                             mustChangeWidth: self.handStateProcessor.mustChangeWidth)
            }
        } catch {
            cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)
            }
        }
    }
}

