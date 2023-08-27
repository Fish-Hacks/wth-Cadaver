//
//  TextService.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 26/8/23.
//

import Foundation
import UIKit
import Vision

class TextService {
    
    var textRequest = VNRecognizeTextRequest()
    
    var results: [VNRecognizedTextObservation] = []
    
    init() {
        textRequest.recognitionLanguages = ["en_US"]
        textRequest.recognitionLevel = .fast
    }
    
    func receiveText(image pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([textRequest])
            
            results = textRequest.results ?? []
        } catch {
        }
    }
}
