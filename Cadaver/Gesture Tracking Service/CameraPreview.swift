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

enum GTSState {
    /// Read off sentence
    case normal
    
    /// Detected context items
    case contextExpanded
    
    /// Using hand to point and read
    case pointer
}

final class CameraPreview: UIView {

    var gtsState = GTSState.normal
    var latestCVResponse: CVResponse?
    
    /// Set up `AVCaptureSession`
    private let captureSession = AVCaptureSession()
    
    /// Set up video output
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var photoOutput = AVCapturePhotoOutput()
    
    var communicationService = CommunicationService()
    
    var speechService = SpeechService()
    
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
        
        handClassifier.delegate = self
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

extension CameraPreview: HandServiceDelegate {
    func didReceiveHand(_ handState: HandState) {
        switch handState {
        case .pointing(let point):
            gtsState = .pointer
            
            let candidateObservations = textService.results.filter { observation in
                observation.boundingBox.contains(point)
            }
            
            if candidateObservations.isEmpty {
                speechService.dictatedText(text: "Nothing to expand to.")
                
            } else {
                for observation in candidateObservations {
                    guard let text = observation.topCandidates(1).first?.string else { continue }
                    
                    speechService.dictatedText(text: "Text: \(text)")
                }
            }
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [self] _ in
                gtsState = .normal
                
                // allow classifier to redetect after 1 second
                handClassifier.previousDetection = .neither
            }
        case .tapping:
            guard let latestCVResponse, gtsState == .normal,
                  let contextCoordinate = latestCVResponse.contextCoordinate else { return }
            
            gtsState = .contextExpanded
                
            // within the frame, find all text
//            textService.results.filter { observation in
//                
//            }
            
        case .neither: break
        }
    }
}

extension CameraPreview: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
        } else if let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData)?.fixOrientation() {
            if gtsState == .normal {
                Task {
                    let cvResponse = await communicationService.sendImageForProcessing(imageData: image.jpegData(compressionQuality: 0.8)!)
                    
                    await MainActor.run { [self] in
                        speechService.dictatedText(text: cvResponse.sceneDescription)
                        latestCVResponse = cvResponse
                    }
                }
            }
        }
    }
}
