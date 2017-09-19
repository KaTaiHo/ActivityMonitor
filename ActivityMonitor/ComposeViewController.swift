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

class ComposeViewController: UIViewController, SFSpeechRecognizerDelegate{

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    
    var player:AVAudioPlayer = AVAudioPlayer()
    var synth:AVSpeechSynthesizer = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    
    var ref: FIRDatabaseReference?

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    func playSong() {
        
        do {
            try player = AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "logic", ofType: "mp3")!))
            player.play()
        }
        catch {
            print("cannot find song")
        }
    }
    
    @IBAction func recordTouched(_ sender: Any) {
        startRecording()
    }
    
    func setupSessionForRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord, with: [.allowBluetooth])
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
        } catch {
            fatalError("Error Setting Up Audio Session")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let userId = FIRAuth.auth()?.currentUser?.uid
        var prefname = " "
        
        ref?.child("users").child(userId!).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            prefname = value?["prefname"] as? String ?? ""
            self.myUtterance = AVSpeechUtterance(string: "Hello " + prefname + "What are you doing right now?")
            self.myUtterance.rate = 0.35
            self.synth.speak(self.myUtterance)
            
        })
        { (error) in
            print(error.localizedDescription)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        
        microphoneButton.isEnabled = false
        speechRecognizer?.delegate = self
        
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
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addPost(_ sender: Any) {
//        ref?.child("Posts").childByAutoId().setValue(textView.text)
        let userId = FIRAuth.auth()?.currentUser?.uid
        
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
        idReference!.setValue(["message": textView.text, "date": todayString, "hour": hour, "minutes": minutes, "reference" : stringReference])
        
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func cancelPost(_ sender: Any) {
        audioEngine.stop()
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
//        let audioSession = AVAudioSession.sharedInstance()
        do {
            
//            try audioSession.setCategory(AVAudioSessionCategoryRecord)
//            try audioSession.setMode(AVAudioSessionModeMeasurement)
//            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
            setupSessionForRecording()
//            try audioSession.setCategory(AVAudioSessionCategoryRecord, with: [.allowBluetooth])
//            try audioSession.setActive(true)

        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
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
        
        textView.text = "Say something, I'm listening!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
}
