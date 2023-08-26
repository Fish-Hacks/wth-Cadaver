//
//  HandClassifier.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 4/4/23.
//

import Foundation
import UIKit
import Vision

class HandClassifier {
    var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    var onRecieveHand: (() -> Void)?
    
    var delegate: HandClassifierDelegate?
    
    var previousClassification: HandClassification = .noHand
    
    init() {
        handPoseRequest.maximumHandCount = 1
    }
    
    func receiveHand(image pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
            
            guard let observation = handPoseRequest.results?.first else {
                delegate?.handClassificationDidUpdate(.noHand, centerPoint: .zero)
                return
            }
            
            let fingerPoints = try observation.recognizedPoints(.all)
            
            let handState = determineHandState(fingerPoints: fingerPoints)
            
            let fingerTipsLocation: [CGPoint]
            
            if handState == .openHand {
                fingerTipsLocation = fingerPoints.compactMap { (key, point) in
                    if point.identifier.rawValue.contains("TIP") && !point.identifier.rawValue.hasPrefix("VNHLKT") {
                        return point.location
                    } else {
                        return nil
                    }
                }
            } else {
                fingerTipsLocation = fingerPoints.compactMap { (key, point) in
                    if point.identifier.rawValue.contains("MCP") {
                        return point.location
                    } else {
                        return nil
                    }
                }
            }
            
            let fingerTipsSum = fingerTipsLocation.reduce(.zero) { (result, point) in
                CGPoint(x: result.x + point.x, y: result.y + point.y)
            }
            
            let fingerTipAverageLocation = CGPoint(x: fingerTipsSum.x / CGFloat(fingerTipsLocation.count),
                                                   y: fingerTipsSum.y / CGFloat(fingerTipsLocation.count))
            
            print(handState)
            delegate?.handClassificationDidUpdate(handState, centerPoint: fingerTipAverageLocation)
        } catch {
            delegate?.handClassificationDidUpdate(.noHand, centerPoint: .zero)
        }
    }
    
    func determineHandState(fingerPoints: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]) -> HandClassification {
        var count = 0
        
        guard let wristLocation = fingerPoints[.wrist]?.location else {
            return .noHand
        }
        
        let confidenceValues = fingerPoints.map { (_, point) in
            point.confidence
        }
        
        let sum = confidenceValues.reduce(0, +)
        let totalConfidence = sum / Float(confidenceValues.count)
        
        guard totalConfidence > 0.7 else { return previousClassification }
        
        if let indexTip = fingerPoints[.indexTip]?.location,
           let indexMCP = fingerPoints[.indexPIP]?.location {
            
            if wristLocation.distance(from: indexTip) < wristLocation.distance(from: indexMCP) {
                count += 1
            }
        }
        
        if let middleTip = fingerPoints[.middleTip]?.location,
           let middleMCP = fingerPoints[.middlePIP]?.location {
            
            if wristLocation.distance(from: middleTip) < wristLocation.distance(from: middleMCP) {
                count += 1
            }
        }
        
        if let ringTip = fingerPoints[.ringTip]?.location,
           let ringMCP = fingerPoints[.ringPIP]?.location {
            
            if wristLocation.distance(from: ringTip) < wristLocation.distance(from: ringMCP) {
                count += 1
            }
        }
        
        if let littleTip = fingerPoints[.littleTip]?.location,
           let littleMCP = fingerPoints[.littlePIP]?.location {
            
            if wristLocation.distance(from: littleTip) < wristLocation.distance(from: littleMCP) {
                count += 1
            }
        }
        
        let classification: HandClassification = count >= 3 ? .closeHand : .openHand
        
        if previousClassification == classification {
            return classification
        } else {
            defer {
                previousClassification = classification
            }
            return previousClassification
        }
    }
    
    enum HandClassification {
        case openHand
        case closeHand
        case noHand
    }
}
