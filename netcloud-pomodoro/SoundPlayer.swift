//
//  SoundPlayer.swift
//  netcloud-pomodoro
//
//  Created by Тимофей Белов on 22.09.2025.
//

import Foundation
import AVFoundation

enum AppSound: String {
    case start, pause, stop, complete
}

final class SoundPlayer {
    static let shared = SoundPlayer()

    private var players: [String: AVAudioPlayer] = [:]
    var volume: Float = 0.8 {                  // 0...1
           didSet { players.values.forEach { $0.volume = volume } }
       }     // 0.0...1.0

    func play(_ sound: AppSound, ext: String = "aiff") {
        let key = "\(sound.rawValue).\(ext)"
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: ext) else {
            // Попробуем wav, если aiff не нашли
            if ext == "aiff" { play(sound, ext: "mp3"); return }
            print("⚠️ Sound not found:", key)
            return
        }
        if let p = players[key] {
            p.currentTime = 0
            p.volume = volume
            p.play()
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = volume
            p.prepareToPlay()
            players[key] = p
            p.play()
        } catch {
            print("❌ Audio error for \(key):", error)
        }
    }
}
