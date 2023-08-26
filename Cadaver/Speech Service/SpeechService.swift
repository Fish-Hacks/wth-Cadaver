//
//  SpeechService.swift
//  Cadaver
//
//  Created by Jimmy Lew on 26/8/23.
//

import Foundation
import AVFoundation

class SpeechService {
    init() {}
    
    func dictatedText(text: String) {
        AVSpeechSynthesizer().speak(AVSpeechUtterance(string: text))
    }
}
