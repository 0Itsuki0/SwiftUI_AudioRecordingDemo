//
//  UIInterfaceOrientation.swift
//  AudioRecordingDemo
//
//  Created by Itsuki on 2025/08/25.
//

import SwiftUI
import AVFAudio

extension UIInterfaceOrientation {
    var stereoOrientation: AVAudioSession.StereoOrientation {
        switch self {
        case .unknown:
                .none
        case .portrait:
                .portrait
        case .portraitUpsideDown:
                .portraitUpsideDown
        case .landscapeLeft:
                .landscapeLeft
        case .landscapeRight:
                .landscapeRight
        @unknown default:
                .none
        }
    }
}
