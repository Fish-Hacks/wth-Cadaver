//
//  HandService.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 4/4/23.
//

import Foundation
import UIKit
import Vision

class HandService {
    var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    var onRecieveHand: (() -> Void)?
    
    var delegate: HandServiceDelegate?
    
    init() {
        handPoseRequest.maximumHandCount = 1
    }
    
    func receiveHand(image pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
            
            guard let observation = handPoseRequest.results?.first else {
                return
            }
            
            let fingerPoints = try observation.recognizedPoints(.all)
            
            guard let indexTipLocation = fingerPoints[.indexTip],
                  let thumbTipLocation = fingerPoints[.thumbTip],
                  let thumbIPLocation = fingerPoints[.thumbIP] else { return }
            
            let reference = thumbTipLocation.location.distance(from: thumbIPLocation.location)
            
            if (thumbTipLocation.location.distance(from: indexTipLocation.location) / reference) < 1.5 {
                print("Tapping")
            } else {
                print("Not")
            }
        } catch {
            
        }
    }
}
