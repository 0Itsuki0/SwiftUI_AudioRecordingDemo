//
//  Error.swift
//  AudioRecordingDemo
//
//  Created by Itsuki on 2025/08/25.
//


import SwiftUI

extension Error {
    var message: String {
        if let error = self as? AudioRecorderManager._Error {
            return error.message
        }
        return self.localizedDescription
    }
}
