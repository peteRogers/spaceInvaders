//
//  ViewController.swift
//  spaceInvaders
//
//  Created by Peter Rogers on 29/03/2023.
//
import UIKit
import Vision
import AVFoundation
import ORSSerial

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, ORSSerialPortDelegate, StartViewDelegate {
    
    
    var audioRecorder: AVAudioRecorder!
    var started = false
    
    // Create a session and preview layer for the camera feed
    let session = AVCaptureSession()
    let previewLayer = AVCaptureVideoPreviewLayer()
    // Create a hand detection request
    let request = VNDetectHumanRectanglesRequest()
    
    let sequenceHandler = VNSequenceRequestHandler()
    
    var ships:[spaceShip] = []
    var missiles:[missile] = []
    var spawnTime = Date()
    var personPos = CGPoint(x: 0, y: 0)
    var fallRate:CGFloat = 2
    var missileSpeed:CGFloat = 7
    var missileShotTime = Date()
    var hitView: ScreenObject?
    var missileSize:CGFloat = 50
    var shipSize:CGFloat = 100
    
    var scoreLabel:UILabel?
    var highScoreLabel:UILabel?
    var startView:StartView?
    var score = 0
    var highScore = 0
    var sunglassesView:ScreenObject!
    var spawnLength:Float = 0
    var hightScore = 0
    
    var serialPort: ORSSerialPort? {
        didSet {
            oldValue?.close()
            oldValue?.delegate = nil
            serialPort?.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        openOrClosePort()
      
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .current, forMode: .common)
        super.viewDidLoad()
        
        // Set up the camera feed
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }
        session.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        session.addOutput(output)
        
        hitView = ScreenObject(frame: self.view.frame)
        sunglassesView = ScreenObject(frame: self.view.frame)
        
        sunglassesView.backgroundColor = .black
        sunglassesView.alpha = 0.8
        
        self.view.addSubview(hitView!)
        previewLayer.session = session
        view.layer.addSublayer(previewLayer)
        
        
        // Start the session
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            
        }
        startRecording()
        scoreLabel = UILabel(frame: CGRect(x: 100, y: 100, width: 900, height: 100))
        scoreLabel?.text = "SCORE"
        scoreLabel?.textColor = .white
        let font = UIFont.systemFont(ofSize: 50.0)
        
        // Set the label's font to the new font object
        scoreLabel?.font = font
        highScoreLabel = UILabel(frame: CGRect(x: 100, y: 200, width: 900, height: 100))
        highScoreLabel?.text = "HIGH SCORE"
        highScoreLabel?.textColor = .white
        highScoreLabel?.font = font
        hitView?.addSubview(scoreLabel!)
        hitView?.addSubview(highScoreLabel!)
        startView = StartView(frame: self.view.frame)
        startView!.delegate = self
        view.addSubview(startView!)
        
        self.view.addSubview(sunglassesView)
        sendData(string: "0")
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Set the preview layer's frame to fit the view
        previewLayer.frame = view.layer.bounds
        hitView!.frame = self.view.bounds
        startView!.frame = self.view.bounds
        sunglassesView.frame = self.view.bounds
        view.bringSubviewToFront(hitView!)
        view.bringSubviewToFront(startView!)
        hitView!.backgroundColor = .clear
        startView!.backgroundColor = .clear
        
    }
    
    
    
    @objc func update() {
        for subview in view.subviews {
            if subview is ScreenObject || subview is StartView{
                
            }else{
                subview.removeFromSuperview()
            }
        }
        
        if(started == true){
            //update ships position
            for index in 0..<ships.count {
                let v = UIView(frame: CGRect(origin: CGPoint(x: ships[index].point.x - (shipSize/2), y: ships[index].point.y - (shipSize/2)) , size: CGSize(width:shipSize,height: shipSize)))
                v.backgroundColor = .red
                self.view.addSubview(v)
                ships[index].point.y += fallRate
                
            }
            
            //update missiles position
            for index in 0..<missiles.count {
                let v = UIView(frame: CGRect(origin: CGPoint(x:missiles[index].point.x-(missileSize/2), y:missiles[index].point.y-(missileSize/2) ), size: CGSize(width:missileSize,height: missileSize)))
                v.backgroundColor = .green
                self.view.addSubview(v)
                missiles[index].point.y -= missileSpeed
            }
            
            //check for hit detection
            for missileIndex in 0..<missiles.count {
                for shipIndex in 0..<ships.count {
                    let distance = hypot(missiles[missileIndex].point.x - ships[shipIndex].point.x, missiles[missileIndex].point.y - ships[shipIndex].point.y)
                    //print(distance)
                    if(distance < shipSize){
                        let v = UIView(frame: CGRect(origin: CGPoint(x: missiles[missileIndex].point.x - shipSize, y:ships[shipIndex].point.y + shipSize/2), size: CGSize(width:shipSize,height: shipSize)))
                        v.backgroundColor = .yellow
                        score = score + 1
                        scoreLabel!.text = "SCORE: \(score)"
                        highScoreLabel!.text = "HIGH SCORE: \(highScore)"
                        hitView?.addSubview(v)
                        self.sendData(string: "foof")
                        explode(loc:v.center)
                        UIView.animate(withDuration: 1.0, delay: 0.01, options: .curveEaseOut, animations: {
                            // Set the alpha value of the view to 0.0 to make it fade out
                            v.alpha = 0.0
                            
                            v.transform = CGAffineTransform(rotationAngle: .pi)
                            v.frame = CGRect(origin: CGPoint(x:v.frame.midX - 100, y: v.frame.midY - 100), size: CGSize(width: 200, height: 200))
                        }, completion: { finished in
                            // This code will be executed when the animation is complete
                            print("Animation finished")
                            v.removeFromSuperview()
                        })
                        // missiles.remove(at:missileIndex)
                        // ships.remove(at:shipIndex)
                        missiles[missileIndex].hit = true
                        ships[shipIndex].hit = true
                        
                    }
                    
                }
                
            }
            
            //spawn new missile
            if(Date.now > spawnTime){
                
                spawnTime = .now.addingTimeInterval(TimeInterval(spawnLength))
                spawnLength = spawnLength - 0.10
                if(spawnLength < 1){
                    spawnLength = 1
                }
                ships.append(spaceShip(point: CGPoint(x: CGFloat.random(in:300...(self.view.frame.width - 300)), y: 0), rotation: 0.0, hit: false, speed: CGFloat.random(in: 2 ... fallRate)))
                fallRate += 0.020
                //print(ships.count)
            }
            
            //remove fallen ships // kill game
            if let index:Int = ships.firstIndex(where: {$0.point.y > self.view.frame.height}) {
                ships.remove(at: index)
                // print("gone")
                
                started = false
                if(score > highScore){
                    highScore = score
                    startView!.showHighScore()
                    sendData(string: "3")
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                        self.sendData(string: "4")
                    }
                }else{
                    startView!.youFailed()
                    sendData(string: "1")
                    Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { timer in
                        self.sendData(string: "2")
                    }
                }
                startView!.activate()
                ships.removeAll()
                missiles.removeAll()
            }
            
            //remove hit ships
            if let index:Int = ships.firstIndex(where: {$0.hit == true}) {
                ships.remove(at: index)
                // print("gone")
            }
            
            if let index:Int = missiles.firstIndex(where: {$0.hit == true}) {
                missiles.remove(at: index)
                // print("gone")
            }
            
            //remove gone missiles
            if let index:Int = missiles.firstIndex(where: {$0.point.y < 0}) {
                missiles.remove(at: index)
                // print("gone")
            }
            
            
            //draw person
            let v = UIView(frame: CGRect(origin: personPos, size: CGSize(width: 300, height: 50)))
            v.backgroundColor = .blue
            self.view.addSubview(v)
        }
        
    }
    
    func explode(loc:CGPoint){
        //let dim = CGFloat.random(in: 10 ... 80)
        for _ in 0 ... Int.random(in: 3...10){
            let dim:CGFloat = CGFloat.random(in: 10...80)
            let v = ExplosionParticle(frame: CGRect(origin: loc, size: CGSize(width: dim, height: dim)))
            
            //v.backgroundColor = .yellow
            //v.setNeedsDisplay()
            hitView?.addSubview(v)
            v.backgroundColor = .clear
            //v.setNeedsDisplay()
            UIView.animate(withDuration: CGFloat.random(in: 0.3 ... 3), delay: 0.01, options: .curveEaseOut, animations: {
                // Set the alpha value of the view to 0.0 to make it fade out
                v.alpha = 0.0
               // v.transform = CGAffineTransform(rotationAngle: .pi)
                v.transform = CGAffineTransform(translationX: CGFloat.random(in: -self.view.frame.width...self.view.frame.width), y: CGFloat.random(in: -self.view.frame.height...self.view.frame.height))
                //v.transform = CGAffineTransform(scaleX: 0, y: 0)
                 
                //v.frame = CGRect(origin: CGPoint(x:CGFloat.random(in: 0...self.view.frame.width), y: CGFloat.random(in: 0...self.view.frame.height)), size: CGSize(width: 1, height: 1))
            }, completion: { finished in
                // This code will be executed when the animation is complete
                // print("Animation finished")
                v.removeFromSuperview()
            })
            
        }
    }
    
    func startViewDidSendMessage(_ message: String) {
        print("Received message: \(message)")
        started = true
        score = 0
        ships.removeAll()
        missiles.removeAll()
        spawnTime =  .now
        spawnLength = 4.0
        highScoreLabel!.text = "HIGH SCORE: \(highScore)"
        scoreLabel!.text = "SCORE: \(score)"
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            let audioURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("audio.m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder.prepareToRecord()
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()
            
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                self.audioRecorder.updateMeters()
                let decibels = self.audioRecorder.averagePower(forChannel: 0)
                if decibels > -8 {
                    if(self.started == true){
                        if(Date.now > self.missileShotTime){
                            self.missileShotTime = .now.addingTimeInterval(TimeInterval(0.2))
                            self.missiles.append(missile(point: CGPoint(x: self.personPos.x + 150, y: self.personPos.y), rotation: 0.0, hit: false))
                        }
                    }
                }
            }
        } catch {
            print("Error starting recording: \(error.localizedDescription)")
        }
    }
    
    
    
    
    
    
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        //ah well
    }
    
    func openOrClosePort() {
        print("port closed")
        let availablePorts = ORSSerialPortManager.shared().availablePorts
        print(availablePorts)
        self.serialPort = ORSSerialPort(path: availablePorts[0].path)
        // self.serialPort = availablePorts[0]
        self.serialPort?.baudRate = 9600
        self.serialPort?.open()
        print("port opened")
        
        
    }
    
    
    
    func serialPort(_ serialPort: ORSSerialPort, didReceivePacket packetData: Data, matching descriptor: ORSSerialPacketDescriptor) {
        if let dataAsString = NSString(data: packetData, encoding: String.Encoding.ascii.rawValue) {
            let valueString = dataAsString.substring(with: NSRange(location: 1, length: dataAsString.length-2))
            
            let inArray = valueString.components(separatedBy: ",")
            print(inArray[0])
            print(inArray[1])
            print(valueString)
            
            if(inArray[1] == "A"){
                
                
                //self.slider.doubleValue = Double(inArray[0])!
                //self.view.layer?.backgroundColor = CGColor.init(gray: CGFloat(slider.doubleValue/1024), alpha: 1)
            }
            if(inArray[1] == "B"){
                //etc etc
            }
            
            
        }
        
    }
    
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        //self.openCloseButton.title = "Close"
        let descriptor = ORSSerialPacketDescriptor(prefixString: "<", suffixString: ">", maximumPacketLength: 8, userInfo: nil)
        serialPort.startListeningForPackets(matching: descriptor)
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        //self.openCloseButton.title = "Open"
    }
    
    
    
    
    func serialPortWasRemoved(fromSystem serialPort: ORSSerialPort) {
        self.serialPort = nil
        // self.openCloseButton.title = "Open"
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        print("SerialPort \(serialPort) encountered an error: \(error)")
    }
    
    func sendData(string:String) {
        let s = "\(string)\n"
        if let data = s.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Create a Core Image buffer from the sample buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Perform the hand detection request
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try? handler.perform([request])
        
        // Process the results
        guard let observations = request.results else {
            return
        }
        if let obs = observations.first{
            DispatchQueue.main.async {
                // print(observation.boundingBox.midX * self.view.frame.width)
                self.personPos.x = (self.view.frame.width - (obs.boundingBox.midX * self.view.frame.width))-150
                
                self.personPos.y = self.view.frame.height - 100
            }
        }

    }
}


struct spaceShip{
    var point:CGPoint
    var rotation:CGFloat
    var hit:Bool
    var speed:CGFloat
}

struct missile{
    var point:CGPoint
    var rotation:CGFloat
    var hit:Bool
}


protocol StartViewDelegate: AnyObject {
    func startViewDidSendMessage(_ message: String)
}











