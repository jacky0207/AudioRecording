//
//  AudioRecorderManager.swift
//  AudioRecording
//
//  Created by Jacky Lam on 29/6/2022.
//

import AVFoundation

class AudioRecorderManager: NSObject {
    
    static let shared = AudioRecorderManager()
    
    private var recordingSession: AVAudioSession!
    
    private var audioRecorder: AVAudioRecorder?
    
    private var audioPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
        
        recordingSession = AVAudioSession.sharedInstance()
    }
    
    // MARK: Permission
    
    private var isRecordPermissionGranted: Bool {
        return recordingSession.recordPermission == .granted
    }
    
    private func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
        switch recordingSession.recordPermission {
        case .undetermined:
            recordingSession.requestRecordPermission { granted in
                print("Record permission is \(granted ? "granted" : "denied")")
                response(granted)
            }
        case .denied:
            print("Record permission is denied")
            return
        case .granted:
            print("Record permission is already granted")
            response(true)  // still do response if granted already
        @unknown default:
            print("Unknown record permission")
            return
        }
    }
    
    // MARK: Directory
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // MARK: Recorder
    
    private let encoderBitRate: Int = 320000
    
    private let numberOfChannels: Int = 2
    
    private let sampleRate: Double = 44100.0
    
    enum RecordingState {
        
        case ready
        
        case recording
        
        case recorded
        
        case playing
    
    }
    
    private(set) var recordingState: RecordingState = .ready {
        didSet {
            NotificationCenter.default.post(
                name: Self.didUpdateRecordingState,
                object: self,
                userInfo: [Self.recordingStateUserInfoKey: recordingState]
            )
        }
    }
    
    func startRecording() {
        startRecording(countDownInterval: nil)
    }
    
    func startRecording(countDownInterval: TimeInterval?) {
        if recordingState != .ready {
            return
        }
        
        if !isRecordPermissionGranted {
            requestRecordPermission { granted in
                DispatchQueue.main.sync {
                    if granted {
                        self.startRecording(countDownInterval: countDownInterval)
                    }
                }
            }
            return
        }
        
        do {  // set recording session active and
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch let error {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        self.countDownInterval = countDownInterval
        
        recordingState = .recording
        
        do {
            let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: NSNumber(value:kAudioFormatAppleLossless),
                AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                AVEncoderBitRateKey : encoderBitRate,
                AVNumberOfChannelsKey: numberOfChannels,
                AVSampleRateKey : sampleRate
            ]
            
            let audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true  // generate audio-level metering data
            audioRecorder.record()
            self.audioRecorder = audioRecorder
            
            // repeat updating audio-level metering data
            metersTimer = Timer.scheduledTimer(withTimeInterval: updateMetersInterval, repeats: true) { _ in
                self.handleUpdateMeters()
            }
            
            // repeat updating count down
            if countDownInterval != nil {
                startCountDown()
            }
        } catch let error {
            print("Error: \(error.localizedDescription)")
            stopRecording()
        }
    }
    
    func stopRecording() {
        if recordingState != .recording {
            return
        }
        
        recordingState = .recorded
        
        metersTimer?.invalidate()
        metersTimer = nil
        
        countDownTimer?.invalidate()
        countDownTimer = nil
        
        audioRecorder?.stop()
    }
    
    func startPlaying() {
        if recordingState != .recorded {
            return
        }
        
        recordingState = .playing
        
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: audioRecorder!.url)
            audioPlayer.delegate = self
            audioPlayer.play()
            self.audioPlayer = audioPlayer
        } catch let error {
            print("Error: \(error.localizedDescription)")
            stopPlaying()
        }
    }
    
    func stopPlaying() {
        if recordingState != .playing {
            return
        }
        
        recordingState = .recorded
        
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func resetRecording() {
        if recordingState != .recorded {
            return
        }
        
        recordingState = .ready
        
        audioRecorder?.deleteRecording()
        audioRecorder = nil
    }
    
    func reset() {
        if recordingState == .ready {
            return
        }
        
        if recordingState == .recording {
            stopRecording()
        }
        
        if recordingState == .playing {
            stopPlaying()
        }
        
        if recordingState == .recorded {
            resetRecording()
        }
    }
    
    // MARK: Meters
    
    private var metersTimer: Timer?
    
    private(set) var updateMetersInterval = 0.05
    
    /// Minimum value of power percentage, expect from 0 to 1. Non-zero value if display ui for no sound
    let minMetersPowerPercentage: Float = 0.01
    
    private func handleUpdateMeters() {
        guard let audioRecorder = audioRecorder else {
            fatalError("Audio recorder must not be nil during updating meters")
        }

        audioRecorder.updateMeters()
        let power = audioRecorder.averagePower(forChannel: 0)
        let powerPercentage: Float = pow(10, (0.05 * power))
        let minPowerPercentage = max(powerPercentage, minMetersPowerPercentage)
        
        NotificationCenter.default.post(
            name: Self.didUpdateMeters,
            object: self,
            userInfo: [Self.meterPowerPercentageUserInfoKey : minPowerPercentage]
        )
    }
    
    // MARK: Count Down Timer
    
    private var countDownTimer: CADisplayLink?  // update for everytime screen refresh
    
    private(set) var countDownInterval: TimeInterval?  // nil if no count down
    
    private var countDownStartTime: Date = Date()
    
    private func startCountDown() {
        countDownStartTime = Date()
        
        let countDownTimer = CADisplayLink(target: self, selector: #selector(handleUpdateCountDownDisplay))
        countDownTimer.add(to: .current, forMode: .common)
        self.countDownTimer = countDownTimer
    }
    
    @objc private func handleUpdateCountDownDisplay() {
        guard let countDownInterval = countDownInterval else {
            fatalError("Count down interval must not be nil for count down action")
        }

        let elapsedTime = (Date().timeIntervalSince1970 - countDownStartTime.timeIntervalSince1970)
        let countDownRemainingTime = countDownInterval - elapsedTime
        
        if countDownRemainingTime > 0 {
            NotificationCenter.default.post(
                name: Self.didUpdateCountDown,
                object: self,
                userInfo: [Self.countDownRemainingTimeUserInfoKey : countDownRemainingTime]
            )
        } else {
            print("Finish recording by finishing count down")
            stopRecording()
        }
    }
    
}

extension AudioRecorderManager {
    
    static let didUpdateRecordingState = Notification.Name("AudioRecordManagerDidUpdateRecordingState")
    
    static let didUpdateMeters = Notification.Name("AudioRecordManagerDidUpdateMeters")
    
    static let didUpdateCountDown = Notification.Name("AudioRecordManagerDidUpdateCountDown")
    
}

extension AudioRecorderManager {
    
    static let recordingStateUserInfoKey = Notification.Name("recordingStateUserInfoKey")
    
    static let meterPowerPercentageUserInfoKey = Notification.Name("meterPowerPercentageUserInfoKey")
    
    static let countDownRemainingTimeUserInfoKey = Notification.Name("countDownRemainingTimeUserInfoKey")
    
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderManager: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Finish recording success: \(flag)")
        
        if !flag {
            stopRecording()  // success finish no need to stop again
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Error: \(error?.localizedDescription ?? "unknown")")
        stopRecording()
    }
    
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecorderManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Finish playing success: \(flag)")
        
        if !flag {
            stopPlaying()  // success finish no need to stop again
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Error: \(error?.localizedDescription ?? "unknown")")
        stopPlaying()
    }
    
}
