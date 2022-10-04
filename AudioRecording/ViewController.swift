//
//  ViewController.swift
//  AudioRecording
//
//  Created by Jacky Lam on 3/10/2022.
//

import UIKit

class ViewController: UIViewController {
    
    private var contentView: UIStackView!
    
    private var recordingStateLabel: UILabel!
    
    private var startRecordingButton: UIButton!
    
    private var stopRecordingButton: UIButton!
    
    private var startPlayingButton: UIButton!
    
    private var stopPlayingButton: UIButton!
    
    private var resetRecordingButton: UIButton!
    
    override func loadView() {
        super.loadView()
        
        contentView = UIStackView(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.axis = .vertical
        contentView.distribution = .fill
        contentView.alignment = .center
        contentView.spacing = 10
        
        recordingStateLabel = UILabel(frame: .zero)
        recordingStateLabel.translatesAutoresizingMaskIntoConstraints = false
        recordingStateLabel.text = "\(AudioRecorderManager.shared.recordingState)"
        
        startRecordingButton = UIButton(type: .roundedRect)
        startRecordingButton.translatesAutoresizingMaskIntoConstraints = false
        startRecordingButton.setTitle("Start Recording", for: .normal)
        startRecordingButton.addTarget(self, action: #selector(handleStartRecording), for: .touchUpInside)
        startRecordingButton.isEnabled = AudioRecorderManager.shared.recordingState == .ready
        
        stopRecordingButton = UIButton(type: .roundedRect)
        stopRecordingButton.translatesAutoresizingMaskIntoConstraints = false
        stopRecordingButton.setTitle("Stop Recording", for: .normal)
        stopRecordingButton.addTarget(self, action: #selector(handleStopRecording), for: .touchUpInside)
        stopRecordingButton.isEnabled = AudioRecorderManager.shared.recordingState == .recording
        
        startPlayingButton = UIButton(type: .roundedRect)
        startPlayingButton.translatesAutoresizingMaskIntoConstraints = false
        startPlayingButton.setTitle("Start Playing", for: .normal)
        startPlayingButton.addTarget(self, action: #selector(handleStartPlaying), for: .touchUpInside)
        startPlayingButton.isEnabled = AudioRecorderManager.shared.recordingState == .recorded
        
        stopPlayingButton = UIButton(type: .roundedRect)
        stopPlayingButton.translatesAutoresizingMaskIntoConstraints = false
        stopPlayingButton.setTitle("Stop Playing", for: .normal)
        stopPlayingButton.addTarget(self, action: #selector(handleStopPlaying), for: .touchUpInside)
        stopPlayingButton.isEnabled = AudioRecorderManager.shared.recordingState == .playing
        
        resetRecordingButton = UIButton(type: .roundedRect)
        resetRecordingButton.translatesAutoresizingMaskIntoConstraints = false
        resetRecordingButton.setTitle("Reset Recording", for: .normal)
        resetRecordingButton.addTarget(self, action: #selector(handleResetRecording), for: .touchUpInside)
        resetRecordingButton.isEnabled = AudioRecorderManager.shared.recordingState == .recorded
        
        view.addSubview(contentView)
        contentView.addArrangedSubview(recordingStateLabel)
        contentView.addArrangedSubview(startRecordingButton)
        contentView.addArrangedSubview(stopRecordingButton)
        contentView.addArrangedSubview(startPlayingButton)
        contentView.addArrangedSubview(stopPlayingButton)
        contentView.addArrangedSubview(resetRecordingButton)
        
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateRecordingState), name: AudioRecorderManager.didUpdateRecordingState, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AudioRecorderManager.shared.reset()  // reset manager state to init state
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AudioRecorderManager.shared.reset()  // reset manager state to init state
    }
    
    // MARK: Recording State
    
    @objc private func handleUpdateRecordingState(notification: Notification) {
        guard let recordingState = notification.userInfo?[AudioRecorderManager.recordingStateUserInfoKey] as? AudioRecorderManager.RecordingState else {
            fatalError("Record state must not be nil")
        }
        
        recordingStateLabel.text = "\(recordingState)"
        startRecordingButton.isEnabled = recordingState == .ready
        stopRecordingButton.isEnabled = recordingState == .recording
        startPlayingButton.isEnabled = recordingState == .recorded
        stopPlayingButton.isEnabled = recordingState == .playing
        resetRecordingButton.isEnabled = recordingState == .recorded
    }
    
    // MARK: Action
    
    @objc private func handleStartRecording() {
        AudioRecorderManager.shared.startRecording()
    }
    
    @objc private func handleStopRecording() {
        AudioRecorderManager.shared.stopRecording()
    }
    
    @objc private func handleStartPlaying() {
        AudioRecorderManager.shared.startPlaying()
    }
    
    @objc private func handleStopPlaying() {
        AudioRecorderManager.shared.stopPlaying()
    }
    
    @objc private func handleResetRecording() {
        AudioRecorderManager.shared.resetRecording()
    }

}
