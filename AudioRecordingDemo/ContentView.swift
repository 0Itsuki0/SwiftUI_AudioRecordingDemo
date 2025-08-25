//
//  ContentView.swift
//  AudioRecordingDemo
//
//  Created by Itsuki on 2025/08/23.
//

import SwiftUI


struct ContentView: View {
    @State private var manager = AudioRecorderManager()
    
    @State private var recordingOption: AudioRecorderManager.RecordingOption = .mono
    @State private var enableMetering: Bool = true

    @State private var startInTime: StartInTime = .now
    @State private var enableDuration: Bool = true
    
    @State private var duration: TimeInterval = 25
    
    enum StartInTime: TimeInterval, CaseIterable {
        case now = 0
        case oneSecond = 1
        case twoSeconds = 2
        case fiveSeconds = 5
        case tenSeconds = 10
        
        var displayString: String {
            switch self {
            case .now:
                "Now"
            case .oneSecond:
                "In 1 Second"
            case .twoSeconds:
                "In 2 Seconds"
            case .fiveSeconds:
                "In 5 Seconds"
            case .tenSeconds:
                "In 10 Seconds"
            }
        }
    }
    

    var body: some View {
        NavigationStack {
            List {
                
                Section("Configurations") {
                    
                    if !manager.availableRecordingOptions.isEmpty {
                        HStack {
                            Text("Recording Option")
                            Spacer()
                            Picker(selection: $recordingOption, content: {
                                ForEach(manager.availableRecordingOptions, id: \.self) { option in
                                    Text(option.displayString)
                                        .tag(option)
                                }
                            }, label: {})
                            .labelsHidden()
                        }
                    }

                    
                    Toggle(isOn: $enableMetering, label: {
                        Text("Enable Power Metering")
                    })

                    
                    HStack {
                        Text("Start Time")
                        Spacer()
                        Picker(selection: $startInTime, content: {
                            ForEach(StartInTime.allCases, id: \.self) { time in
                                Text(time.displayString)
                                    .tag(time)
                            }
                        }, label: {})
                        .labelsHidden()
                    }
                    
                    
                    VStack(spacing: 24) {
                        Toggle(isOn: $enableDuration, label: {
                            Text("Set Recording Duration")
                        })

                        if enableDuration {
                            HStack {
                                Text("Duration (sec)")
                                
                                Spacer()
                                
                                TextField("", value: $duration, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            .foregroundStyle(.secondary)

                        }
                    }
                    
                }
                
                Section {
                    switch manager.recorderState {
                    case .reserved(let remaining):
                        HStack {
                            Text("Recording starts in")
                            Text(remaining.secondString)
                                .foregroundStyle(.secondary)
                            Spacer()
                            button(imageName: "stop.circle", action: {
                                manager.stopRecording()
                            })
                        }
                    case .stopped:
                        Button(action: {
                            Task {
                                do {
                                    try await manager.startRecording(in: self.startInTime == .now ? nil : self.startInTime.rawValue, forDuration: self.enableDuration ? self.duration : nil, recordingOption: self.recordingOption, enableMetering: self.enableMetering)
                                } catch (let error) {
                                    manager.error = error
                                }
                            }
                        }, label: {
                            if manager.recordedContentsDuration != nil {
                                Text("Start New Recording")
                            } else {
                                Text("Start Recording")
                            }
                        })
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(.all, 0)
                        .listRowBackground(Color.blue)
                        
                    case .paused(let elapsed, let powerMetrics):
                        
                        VStack(spacing: 24) {
                            HStack {
                                Text("Recording paused")
                                Spacer()
                                HStack(spacing: 16) {
                                    button(imageName: "stop.circle", action: {
                                        manager.stopRecording()
                                    })
                                    
                                    button(imageName: "play.circle", action: {
                                        do {
                                            try manager.resumeRecording()
                                        } catch (let error) {
                                            manager.error = error
                                        }
                                    })
                                    
                                }
                            }
                            
                            recordingMetricsView(elapsed: elapsed, powerMetrics: powerMetrics)

                        }

                    case .started(let elapsed, let powerMetrics):
                        
                        VStack(spacing: 24) {
                            HStack {
                                Text("Recording")
                                Spacer()
                                HStack(spacing: 16) {
                                    button(imageName: "stop.circle", action: {
                                        manager.stopRecording()
                                    })

                                    button(imageName: "pause.circle", action: {
                                        manager.pauseRecording()
                                    })

                                }
                            }

                            recordingMetricsView(elapsed: elapsed, powerMetrics: powerMetrics)
                            
                        }
                    }

                }
                
                
  
                if let destinationURL = manager.destinationURL, let recordedContentsDuration = manager.recordedContentsDuration {
                    Section {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Recording Finished")
                            
                            HStack {
                                
                                Text("Duration: \(recordedContentsDuration.secondString)")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                HStack(spacing: 16) {
                                    ShareLink(item: destinationURL, label: {
                                        Image(systemName: "square.and.arrow.up")
                                            .resizable()
                                            .scaledToFit()
                                            .contentShape(.circle)
                                            .padding(.bottom, 2)
                                            .frame(height: 16)
                                    })
                                    .buttonStyle(.glassProminent)
                                    
                                    if !manager.isPlayingRecording {
                                        button(imageName: "play.circle", action: {
                                            do {
                                                try manager.resumePlayingRecording()
                                            } catch (let error) {
                                                manager.error = error
                                            }
                                        })
                                    } else {
                                        button(imageName: "pause.circle", action: {
                                            manager.pausePlayingRecording()
                                        })

                                    }

                                }
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .alert("Oops!", isPresented: $manager.showError, actions: {
                Button(action: {
                    manager.showError = false
                }, label: {
                    Text("OK")
                })
            }, message: {
                Text("\(manager.error?.message ?? "Unknown Error")")
            })
            .navigationTitle("AVAudioRecorder")
            .navigationBarTitleDisplayMode(.large)
        }

    }
    
    private func button(imageName: String, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .contentShape(.circle)
                .frame(width: 32)
        })
        .buttonStyle(.borderless)
    }
    
    private func recordingMetricsView(elapsed: TimeInterval, powerMetrics: [AudioRecorderManager.PowerMetrics] ) -> some View {

        // 0 dBFS, indicating maximum power.
        let maxPower: Float = 0.0
        // –160 dBFS, indicating minimum power,
        let minPower: Float = -160.0
        let total = maxPower.linearPower - minPower.linearPower

        return Group {
            if self.enableDuration {
                ProgressView(value: elapsed, total: self.duration, label: {
                    Text("Elapsed: \(elapsed.secondString). \nTotal: \(self.duration.secondString)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                })
            } else {
                Text("Elapsed time: \(elapsed.secondString)")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            ForEach(powerMetrics, id: \.self) { metric in
                
                let linearAverage = metric.average.linearPower
                let linearPeak = metric.peak.linearPower
                
                VStack {
                    Text(String("Channel: \(metric.channelName ?? (metric.channelNumber == 0 ? "Left" : "Right"))"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    ProgressView(value: linearAverage, total: total, label: {
                        Text("Average Power: \(metric.average.powerString)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    })

                    ProgressView(value: linearPeak, total: total, label: {
                        Text("Peak Power: \(metric.peak.powerString)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    })

                }

            }
            

        }
    }
    
}


#Preview {
    ContentView()
}
