import Foundation
import AppKit
import Combine
import AVFoundation

private struct EventPayload: Codable {
    let session_id: String
    let action: String
    let duration_sec: Int?
    let remaining_sec: Int?
    let timestamp: String
    let user_id: String?
}
final class TimerViewModel: ObservableObject {
    // Публичные (для биндинга)
    @Published var remaining: TimeInterval
    @Published var durationMinutes: Int
    @Published var autoRepeat: Bool
    @Published var soundEnabled: Bool = true
    @Published var soundVolume: Double = 1.0   // 0...1

    // Внутренние
    private var timer: Timer?
    private(set) var isRunning: Bool
    private(set) var hasSession: Bool
    private var sessionId: String?
    private let apiURL: URL

    // === ИНИЦИАЛИЗАТОР ===
    init(apiEndpoint: String = "https://services.netcloud.dev/api/v1/pomodoro") {
        self.remaining = 0
        self.durationMinutes = 25
        self.autoRepeat = true
        self.timer = nil
        self.isRunning = false
        self.hasSession = false
        self.sessionId = nil
        self.apiURL = URL(string: apiEndpoint)!
    }

    // MARK: - Публичные свойства-вью
    var menuTitle: String {
        isRunning || hasSession ? Self.format(remaining) : ""
    }
    
    var stateDescription: String {
        if isRunning { return "Идёт сессия: \(Self.format(remaining))" }
        if hasSession { return "На паузе: \(Self.format(remaining))" }
        return "Сессия не запущена"
    }

    // MARK: - Управление
    func start() {
        if !hasSession {
            remaining = TimeInterval(durationMinutes * 60)
            createSessionOnServer()
            hasSession = true
        }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        if soundEnabled {
               SoundPlayer.shared.volume = Float(soundVolume)
               SoundPlayer.shared.play(.start)
           }
        RunLoop.main.add(timer!, forMode: .common)
        objectWillChange.send()
        sendEvent("start_or_resume")
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        objectWillChange.send()
        if soundEnabled {
                SoundPlayer.shared.volume = Float(soundVolume)
                SoundPlayer.shared.play(.pause)
            }
        sendEvent("pause")
    }

    func stop() {
        timer?.invalidate()
        isRunning = false
        hasSession = false
        objectWillChange.send()
        sendEvent("stop")
        if soundEnabled {
                SoundPlayer.shared.volume = Float(soundVolume)
                SoundPlayer.shared.play(.stop)
            }
        sessionId = nil
    }

    private func tick() {
        guard remaining > 0 else {
            timer?.invalidate()
            isRunning = false
            objectWillChange.send()
            sendEvent("complete")
            if soundEnabled {
                    SoundPlayer.shared.volume = Float(soundVolume)
                    SoundPlayer.shared.play(.complete)
                }
            if autoRepeat {
                hasSession = false
                start()
            }
            return
        }
        remaining -= 1
        objectWillChange.send()
        NSApp.dockTile.badgeLabel = isRunning ? Self.format(remaining) : nil
    }

    // MARK: - Сеть
    private func createSessionOnServer() {
        sessionId = UUID().uuidString
         let payload = EventPayload(
             session_id: sessionId!,
             action: "create",
             duration_sec: durationMinutes * 60,
             remaining_sec: Int(remaining),
             timestamp: ISO8601DateFormatter().string(from: .now),
             user_id: nil
         )
         postJSON(payload)
    }

    private func sendEvent(_ action: String) {
        guard let sessionId else { return }
           let payload = EventPayload(
               session_id: sessionId,
               action: action,
               duration_sec: nil,                        // или durationMinutes*60, если хотите дублировать
               remaining_sec: Int(remaining),
               timestamp: ISO8601DateFormatter().string(from: .now),
               user_id: nil
           )
           postJSON(payload)
    }

    private func postJSON(_ payload: EventPayload) {
        var req = URLRequest(url: apiURL)           // убедитесь, что apiURL = http://127.0.0.1:3000/pomodoro
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Если используете ключ:
        // req.setValue("supersecret", forHTTPHeaderField: "x-api-key")

        do {
            let body = try JSONEncoder().encode(payload)
            req.httpBody = body
            // DEBUG: покажем, что реально уходит
            if let s = String(data: body, encoding: .utf8) {
                print("➡️ POST /pomodoro body:", s)
            }
        } catch {
            print("❌ JSON encode failed:", error)
            return
        }

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { print("❌ POST error:", err); return }
            if let http = resp as? HTTPURLResponse {
                print("✅ STATUS:", http.statusCode)
            }
            if let data = data, let txt = String(data: data, encoding: .utf8) {
                print("⬅️ RESPONSE:", txt)
            }
        }.resume()
    }

    // MARK: - Утиль
    static func format(_ t: TimeInterval) -> String {
        let s = max(0, Int(t))
        return String(format: "%02d:%02d", s/60, s%60)
    }
}
