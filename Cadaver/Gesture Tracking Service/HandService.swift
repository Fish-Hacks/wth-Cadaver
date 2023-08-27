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
    
    var handStateQueue: [HandState] = []
    
    var previousDetection = HandState.neither
    
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
                  let thumbIPLocation = fingerPoints[.thumbIP],
                  let wristLocation = fingerPoints[.wrist] else { return }
            
            let reference = thumbTipLocation.location.distance(from: thumbIPLocation.location)
            
            if (indexTipLocation.location.distance(from: wristLocation.location) / reference) > 5 {
                handStateQueue.append(.pointing(indexTipLocation.location))
            } else if (thumbTipLocation.location.distance(from: indexTipLocation.location) / reference) < 1.5 {
                handStateQueue.append(.tapping)
            } else {
                handStateQueue.append(.neither)
            }
            
            if handStateQueue.count == 6 {
                handStateQueue.removeFirst()
            }
            
            let allPointing = handStateQueue.allSatisfy {
                $0.isPointing()
            }
            
            let allTapping = handStateQueue.allSatisfy {
                $0 == .tapping
            }
            
            if allPointing && !previousDetection.isPointing() {
                delegate?.didReceiveHand(.pointing(indexTipLocation.location))
                previousDetection = .pointing(indexTipLocation.location)
            } else if allTapping && previousDetection != .tapping {
                delegate?.didReceiveHand(.tapping)
                previousDetection = .tapping
            } else {
                delegate?.didReceiveHand(.neither)
                previousDetection = .neither
            }
        } catch {
            
        }
    }
}

enum HandState: Equatable {
    case pointing(CGPoint)
    case tapping
    case neither
    
    func isPointing() -> Bool {
        switch self {
        case .pointing(_): return true
        default: return false
        }
    }
}
