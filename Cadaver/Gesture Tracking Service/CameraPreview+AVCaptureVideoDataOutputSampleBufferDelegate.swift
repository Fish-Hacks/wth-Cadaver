//
//  CameraPreview+AVCaptureVideoDataOutputSampleBufferDelegate.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 26/8/23.
//

import Foundation
import AVFoundation
import Vision
import UIKit

extension CameraPreview: AVCaptureVideoDataOutputSampleBufferDelegate {
    // Receives input on every frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        handClassifier.receiveHand(image: pixelBuffer)
    }
}
