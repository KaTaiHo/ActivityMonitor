//
//  ComposeViewController.swift
//  ActivityMonitor
//
//  Created by Ka Tai Ho on 8/29/17.
//  Copyright © 2017 SDLtest. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import Speech
import AVFoundation
import UserNotifications

class ComposeViewController: UIViewController, SFSpeechRecognizerDelegate, UNUserNotificationCenterDelegate{

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    
    var userVoiceInput = ""
    var backgroundTask = BackgroundTask()
    var textToSpeechTimerBackground = Timer()
    var recordTimerBackground = Timer()
    var recordTimer = Timer()
    
    var userId: String?
    var ref: FIRDatabaseReference?

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    var audioEngine = AVAudioEngine()
    
    func initNotificationSetupCheck() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
        { (success, error) in
            if success {
                print("Permission Granted")
            } else {
                print("There was a problem!")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func sendNotification() {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: { (success, error) in
            // handle error
        })
        
        let notification = UNMutableNotificationContent()
        notification.title = "Activity Monitor"
        notification.subtitle = "Collecting data"
        notification.body = "What are you currently doing right now?"
        
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "notification1", content: notification, trigger: notificationTrigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            // handle error
        })
    }
    
    func setupSessionForRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.allowBluetooth])
            //AVAudioSessionCategoryPlayAndRecord,
        } catch {
            fatalError("Error Setting Up Audio Session")
        }
        var inputsPriority: [(type: String, input: AVAudioSessionPortDescription?)] = [
            (AVAudioSessionPortLineIn, nil),
            (AVAudioSessionPortHeadsetMic, nil),
            (AVAudioSessionPortBluetoothHFP, nil),
            (AVAudioSessionPortUSBAudio, nil),
            (AVAudioSessionPortCarAudio, nil),
            (AVAudioSessionPortBuiltInMic, nil),
            ]
        for availableInput in audioSession.availableInputs! {
            guard let index = inputsPriority.index(where: { $0.type == availableInput.portType }) else { continue }
            inputsPriority[index].input = availableInput
        }
        guard let input = inputsPriority.filter({ $0.input != nil }).first?.input else {
            fatalError("No Available Ports For Recording")
        }
        do {
            try audioSession.setPreferredInput(input)
            try audioSession.setActive(true)
        }
        catch {
            fatalError("Error Setting Up Audio Session")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        userId = FIRAuth.auth()?.currentUser?.uid
        
        UNUserNotificationCenter.current().delegate = self
        
        speechRecognizer?.delegate = self
        
        setupSessionForRecording()
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
        }
    }
    
    func addPostFunc () {
        let todaysDate:NSDate = NSDate()
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        let todayString:String = dateFormatter.string(from: todaysDate as Date)
        
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        
        let idReference = self.ref?.child("users").child(userId!).child("Posts").childByAutoId()
        let stringReferenceArr = String(describing: idReference!).components(separatedBy: "/")
        let stringReference = stringReferenceArr[stringReferenceArr.count - 1]
        idReference!.setValue(["message": self.userVoiceInput, "date": todayString, "hour": hour, "minutes": minutes, "reference" : stringReference])

//        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func cancelPost(_ sender: Any) {
        audioEngine.stop()
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func startRecording() {
        print("starting to record the user")
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        setupSessionForRecording()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        self.textView.text = "Say something, I'm listening!"
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                self.userVoiceInput = (result?.bestTranscription.formattedString)!
                self.textView.text = self.userVoiceInput
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                self.audioEngine.inputNode?.removeTap(onBus: 0)
                
                self.recognitionRequest?.endAudio()
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.recordTimer.invalidate()
                
                if self.userVoiceInput == "" {
                    self.userVoiceInput = "no response"
                }
                self.addPostFunc()
                print("done recording")
                if let error = error {
                     print("There was an error: \(error)")
                }
            }
            else {
                self.recordTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: {
                    (recordTimer) in
                    print("in recording mode")
                    isFinal = true
                    
                    self.audioEngine.stop()
                    self.audioEngine.inputNode?.removeTap(onBus: 0)
                    
                    self.recognitionRequest?.endAudio()
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    self.recordTimer.invalidate()
                })
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }
    
    func pollUser(){
        print("Just asked the user something")
        self.playAudio()
        self.startRecording()
        self.userVoiceInput = ""
    }
    
    func playAudio() {
        self.audioEngine.inputNode?.removeTap(onBus: 0)
        let myUtterance = AVSpeechUtterance(string: "Hello, What are you doing right now?")
        myUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        let synth = AVSpeechSynthesizer()
        myUtterance.rate = 0.45
        synth.speak(myUtterance)
        print("done asking the user how they are doing")
    }
    
    @IBAction func startSession(_ sender: Any) {
//        backgroundTask.startBackgroundTask()
//        playAudio()
        
        textToSpeechTimerBackground = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.pollUser), userInfo: nil, repeats: true)
        
//        recordTimerBackground = Timer.scheduledTimer(timeInterval: 21, target: self, selector: #selector(self.startRecording), userInfo: nil, repeats: true)
//        for index in 0...10 {
//            self.pollUser()
//            sleep(20)
//        }
        
        startButton.alpha = 0.5
        startButton.isUserInteractionEnabled = false
        
        pauseButton.alpha = 1
        pauseButton.isUserInteractionEnabled = true
    }
    
    @IBAction func pauseSession(_ sender: Any) {
        startButton.alpha = 1
        startButton.isUserInteractionEnabled = true
        pauseButton.alpha = 0.5
        pauseButton.isUserInteractionEnabled = false
        
        textToSpeechTimerBackground.invalidate()
//        recordTimerBackground.invalidate()
//        backgroundTask.stopBackgroundTask()
    }
}
