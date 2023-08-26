//
//  SpeechService.swift
//  Cadaver
//
//  Created by Jimmy Lew on 26/8/23.
//

import Foundation
import AVFoundation

class SpeechService {
    
    let synthesizer = AVSpeechSynthesizer()
    
    init() {}
    
    func dictatedText(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        
        let voice = AVSpeechSynthesisVoice(language: "en-GB")!
        
        utterance.voice = voice
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        synthesizer.speak(utterance)
    }
}
