//
//  netcloud_pomodoroApp.swift
//  netcloud-pomodoro
//
//  Created by Тимофей Белов on 22.09.2025.
//

import SwiftUI
import Cocoa

@main
struct netcloud_pomodoroApp: App {
    @StateObject private var timerVM = TimerViewModel()

        var body: some Scene {
            // Иконка + динамический заголовок "мм:сс" в меню-баре
            MenuBarExtra {
                VStack(alignment: .leading, spacing: 8) {
                    
                    Text("NCLD SERVICES")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                    Divider();
                    Text("Помодоро")
                        .font(.title3)
                        .foregroundStyle(.green)
                    Divider();
                    Text(timerVM.stateDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    VStack {
                        Button(timerVM.isRunning ? "Пауза" : "Начать") {
                            timerVM.isRunning ? timerVM.pause() : timerVM.start()
                        }
                        Button("Завершить") { timerVM.stop() }
                            .disabled(!timerVM.hasSession)
                        Divider();
                        Text("Фаст-линки")
                            .font(.title3)
                            .foregroundStyle(.green)
                        Divider();
                        Button("Сервисы") {
                            
                            let url = URL(string: "https://services.netcloud.dev")!
                            if NSWorkspace.shared.open(url) {
                                print("default browser was successfully opened")

                            }
                        }
                        Button("Timeweb") {
                            
                            let url = URL(string: "https://timeweb.cloud")!
                            if NSWorkspace.shared.open(url) {
                                print("default browser was successfully opened")

                            }
                        }
                        Button("Yandex Cloud") {
                            
                            let url = URL(string: "https://console.yandex.cloud")!
                            if NSWorkspace.shared.open(url) {
                                print("default browser was successfully opened")

                            }
                        }
                        
                    }

                    Divider()

                    Picker("Длительность", selection: $timerVM.durationMinutes) {
                        ForEach([15, 20, 25, 30, 50], id: \.self) { m in
                            Text("\(m) мин").tag(m)
                        }
                    }
                    .labelsHidden()

                    Toggle("Автоповтор (Помодоро)", isOn: $timerVM.autoRepeat)
                    
                    Toggle("Звук", isOn: $timerVM.soundEnabled)

                    HStack {
                        Text("Громкость").font(.caption)
                        Slider(value: $timerVM.soundVolume, in: 0...1, step: 0.05)
                            .frame(width: 140)
                        
                        Text("\(Int(timerVM.soundVolume * 100))%")
                            .font(.caption)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(width: 300)
            } label: {
                // Кастомная иконка + текст в строке меню
                HStack(spacing: 4) {
                    Image("BarIcon")                // <- ваш ассет из Assets
                        .renderingMode(.template)   // чтобы подстраивалась под тему
                        .help("Pomodoro")
                    Text(timerVM.menuTitle)                    // или timerVM.menuTitle для времени
                        .monospacedDigit()
                }
            }
            .menuBarExtraStyle(.menu)
        }
}
