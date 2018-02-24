//
//  ViewController.swift
//  Aurora
//
//  Created by Amirmehdi Sharifzad on 2018-02-24.
//  Copyright © 2018 Hack The Valley II. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /*
    // 2) access the AVSpeechSynthesizer Class
    let speakTalk = AVSpeechSynthesizer()
    
    // 3) create AVSpeechutterance instance using string
    let Aurora = AVSpeechUtterance(string: "No, my name is Aurora" )
    
    @IBOutlet weak var theWordsInTheTextField: UITextField!
    
    @IBAction func speakText(sender: AnyObject) {
        
        // *create AVSpeechUtterance instance using text in the field
        let speakText = AVSpeechUtterance(string: theWordsInTheTextField.text!)
        
        // *adjust the rate and pitch of each Utterance instance in the function
        // -rate: float (min, max) = (0.0 to 1.0)
        // -pitchMultiplier:float  (min,max) = (0.5 to 2.0)
        Aurora.rate = 0.6
        Aurora.pitchMultiplier = 2
        speakText.rate = 0.2
        speakText.pitchMultiplier = 0.1
        
        // 4) pass the utterance instance(s) to the speakUtterance methods queue
        speakTalk.speak(speakText)
        speakTalk.speak(Aurora)
        
    }  */

    let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Label"
        label.font = label.font.withSize(30)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupCaptureSession()
        
        view.addSubview(label)
        setupLabel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func setupCaptureSession() {
        // creates a new capture session
        let captureSession = AVCaptureSession()
        
        // search for available capture devices
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        
        // get capture device, add device input to capture session
        do {
            if let captureDevice = availableDevices.first {
                captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice))
            }
        } catch {
            print(error.localizedDescription)
        }
    
        // setup output, add output to our capture session
        let captureOutput = AVCaptureVideoDataOutput()
        captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        captureSession.addOutput(captureOutput)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        
        captureSession.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let model = try? VNCoreMLModel(for: MobileNet().model) else { return }
        // 2) access the AVSpeechSynthesizer Class
        let speakTalk = AVSpeechSynthesizer()
        
        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
            guard let results = finishedRequest.results //as? [VNClassificationObservation]
                else { return }
            guard let Observation = results.first
                .flatMap({ $0 as? VNClassificationObservation })
                else { return }
            let classifications = results[0...4]
                .flatMap({ $0 as? VNClassificationObservation })
                .filter({ $0.confidence > 0.5 })
                .map {
                    (prediction: VNClassificationObservation) -> String in
                    return "\(round(prediction.confidence * 100 * 100)/100)%: \(prediction.identifier)"
            }
            
            DispatchQueue.main.async(execute: {
                var obj = ""   
                if Observation.confidence > 0.5 {
                    obj = Observation.identifier
                }
                let talk = AVSpeechUtterance(string: obj)
                self.label.text = classifications.joined(separator: "\n")    //"\(Observation.identifier)"
                speakTalk.speak(talk)
            })
        }
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // executes request
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func setupLabel() {
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
    }
    
}

