//
//  CameraPreview.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 26/8/23.
//

import Foundation
import Vision
import AVFoundation
import UIKit

final class CameraPreview: UIView {
    
    /// Set up `AVCaptureSession`
    private let captureSession = AVCaptureSession()
    
    /// Set up video output
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var photoOutput = AVCapturePhotoOutput()
    
    var communicationService = CommunicationService()
    
    var handClassifier = HandService()
    var textService = TextService()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCaptureSession()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCaptureSession()
    }

    /// Get camera size
    var size: CGSize!
    
    /// Set up AVCaptureSession
    ///
    /// - Create capture device
    /// - Set up with inputs
    /// - Set up camera preview layer
    private func setupCaptureSession() {
        captureSession.beginConfiguration()

        guard let captureDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back),
              let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
              captureSession.canAddInput(captureDeviceInput) else { fatalError() }
        
        size = CGSize(width: CGFloat(captureDevice.activeFormat.supportedMaxPhotoDimensions.first!.width),
                      height: CGFloat(captureDevice.activeFormat.supportedMaxPhotoDimensions.first!.height))

        captureSession.addInput(captureDeviceInput)

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        captureSession.addOutput(photoOutput)

        captureSession.commitConfiguration()
        
        DispatchQueue.global(qos: .utility).async {
            self.captureSession.startRunning()
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.takePhoto()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let previewLayer = layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = bounds
        }
    }
    
    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraPreview: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
        } else if let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData)?.fixOrientation() {
            communicationService.sendImageForProcessing(imageData: image.jpegData(compressionQuality: 1)!)
        }
    }
}
