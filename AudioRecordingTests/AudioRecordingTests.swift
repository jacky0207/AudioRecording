//
//  AudioRecordingTests.swift
//  AudioRecordingTests
//
//  Created by Jacky Lam on 3/10/2022.
//

import XCTest
@testable import AudioRecording

class AudioRecordingTests: XCTestCase {
    
    var manager: AudioRecorderManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        manager = AudioRecorderManager.shared
    }

    override func tearDownWithError() throws {
        manager.reset()
        try super.tearDownWithError()
    }

    func testStartRecording() throws {
        manager.startRecording()
        XCTAssertEqual(manager.recordingState, .recording)
    }
        
    func testStopRecording() throws {
        manager.startRecording()
        manager.stopRecording()
        XCTAssertEqual(manager.recordingState, .recorded)
    }
    
    func testStartPlaying() throws {
        manager.startRecording()
        manager.stopRecording()
        manager.startPlaying()
        XCTAssertEqual(manager.recordingState, .playing)
    }
        
    func testStopPlaying() throws {
        manager.startRecording()
        manager.stopRecording()
        manager.startPlaying()
        manager.stopPlaying()
        XCTAssertEqual(manager.recordingState, .recorded)
    }
     
    func testResetRecording() throws {
        manager.startRecording()
        manager.stopRecording()
        manager.startPlaying()
        manager.stopPlaying()
        manager.resetRecording()
        XCTAssertEqual(manager.recordingState, .ready)
    }
    
    func testReset() throws {
        manager.startRecording()
        manager.reset()
        XCTAssertEqual(manager.recordingState, .ready)
        
        manager.startRecording()
        manager.stopRecording()
        manager.reset()
        XCTAssertEqual(manager.recordingState, .ready)
    }
    
    func testUpdateRecordingStateNotification() throws {
        expectation(
            forNotification: AudioRecorderManager.didUpdateRecordingState,
            object: manager,
            handler: { notification in
                guard let recordingState = notification.userInfo?[AudioRecorderManager.recordingStateUserInfoKey] as? AudioRecorderManager.RecordingState else {
                    return false
                }
                
                XCTAssertEqual(recordingState, .recording)
                
                return true
            }
        )
        
        manager.startRecording()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testUpdateMetersInterval() throws {
        expectation(
            forNotification: AudioRecorderManager.didUpdateMeters,
            object: manager,
            handler: { notification in
                guard let _ = notification.userInfo?[AudioRecorderManager.meterPowerPercentageUserInfoKey] as? Float else {
                    return false
                }
                
                return true
            }
        )
        
        manager.startRecording()
        waitForExpectations(timeout: manager.updateMetersInterval, handler: nil)
    }
    
    func testUpdateCountDown() throws {
        expectation(
            forNotification: AudioRecorderManager.didUpdateCountDown,
            object: manager,
            handler: { notification in
                guard let _ = notification.userInfo?[AudioRecorderManager.countDownRemainingTimeUserInfoKey] as? Double else {
                    return false
                }
                
                return true
            }
        )
        
        manager.startRecording(countDownInterval: 1)
        waitForExpectations(timeout: 1, handler: nil)
    }

}
