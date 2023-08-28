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
        utterance.rate = 0.58
        
        let voice = AVSpeechSynthesisVoice(language: "en-GB")!
        
        utterance.voice = voice
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        synthesizer.speak(utterance)
        
        print("saying", text)
    }
}
