//
//  CameraCell.swift
//  Pods
//
//  Created by Joakim Gyllström on 2015-09-26.
//
//

import UIKit
import AVFoundation

/**
*/
final class CameraCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraBackground: UIView!
    var cameraOverlayView: UIView?
    var cameraOverlayAlpha: CGFloat {
        get {
            return cameraOverlayView?.alpha ?? 0
        }
        set {
            if cameraOverlayView == nil {
                let overlayView = UIView(frame: cameraBackground.bounds)
                overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                overlayView.backgroundColor = .black
                overlayView.isHidden = true
                cameraBackground.addSubview(overlayView)
                cameraOverlayView = overlayView
            }
            cameraOverlayView?.alpha = newValue
        }
    }
    @objc var takePhotoIcon: UIImage? {
        didSet {
            imageView.image = session?.isRunning == true ? takePhotoIcon?.withRenderingMode(.alwaysTemplate) : takePhotoIcon
        }
    }
    
    @objc var session: AVCaptureSession? { return captureLayer?.session }
    @objc var captureLayer: AVCaptureVideoPreviewLayer?
    @objc let sessionQueue = DispatchQueue(label: "AVCaptureVideoPreviewLayer", attributes: [])

    private var observers = [NSObjectProtocol]()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Don't trigger camera access for the background
        guard AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized else {
            return
        }
        
        do {
            // Prepare avcapture session
            let session = AVCaptureSession()
            session.sessionPreset = AVCaptureSession.Preset.medium
            
            // Hook upp device
            let device = AVCaptureDevice.default(for: AVMediaType.video)
            let input = try AVCaptureDeviceInput(device: device!)
            session.addInput(input)
            
            // Setup capture layer

            let captureLayer = AVCaptureVideoPreviewLayer(session: session)
            captureLayer.frame = bounds
            captureLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            cameraBackground.layer.addSublayer(captureLayer)
            self.captureLayer = captureLayer

            observers = [
                NotificationCenter.default.addObserver(forName: .AVCaptureSessionDidStartRunning, object: session, queue: .main, using: self.handleRunningStateChangeNotification(_:)),
                NotificationCenter.default.addObserver(forName: .AVCaptureSessionDidStopRunning, object: session, queue: .main, using: self.handleRunningStateChangeNotification(_:)),
                NotificationCenter.default.addObserver(forName: .AVCaptureSessionWasInterrupted, object: session, queue: .main, using: self.handleRunningStateChangeNotification(_:)),
            ]
        } catch {
            // Do nothing.
        }
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        captureLayer?.frame = bounds
    }
    
    @objc func startLiveBackground() {
        sessionQueue.async { () -> Void in
            self.session?.startRunning()
        }
    }
    
    @objc func stopLiveBackground() {
        sessionQueue.async { () -> Void in
            self.session?.stopRunning()
        }
    }

    private func handleRunningStateChangeNotification(_ : Notification) {
        guard let session = session else { return }
        captureLayer?.isHidden = !session.isRunning
        if let cameraOverlayView = cameraOverlayView {
            cameraOverlayView.isHidden = !session.isRunning
            cameraOverlayView.bringSubviewToFront(cameraOverlayView)
        }
        imageView.image = session.isRunning ? takePhotoIcon?.withRenderingMode(.alwaysTemplate) : takePhotoIcon
    }
}
