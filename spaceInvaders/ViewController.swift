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

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, ORSSerialPortDelegate {
   
    
    var audioRecorder: AVAudioRecorder!
    
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
    
    var score = 0
    
    
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
        // Do any additional setup after loading the view.
        
//        for  _ in 0 ... 20{
//            ships.append(spaceShip(point: CGPoint(x: CGFloat.random(in: 1...self.view.frame.width), y: CGFloat.random(in: 1...50)), rotation: 0.0))
//        }
        spawnTime = .now.addingTimeInterval(TimeInterval(2.5))
        //print(spawnTime)
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
        self.view.addSubview(hitView!)
        previewLayer.session = session
        view.layer.addSublayer(previewLayer)
       
        
        // Start the session
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
           
        }
        startRecording()
        scoreLabel = UILabel(frame: CGRect(x: 100, y: 100, width: 400, height: 100))
        scoreLabel?.text = "ScoreLabel"
        let font = UIFont.systemFont(ofSize: 30.0)

        // Set the label's font to the new font object
        scoreLabel?.font = font
        hitView?.addSubview(scoreLabel!)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Set the preview layer's frame to fit the view
        previewLayer.frame = view.layer.bounds
        hitView!.frame = self.view.bounds
        view.bringSubviewToFront(hitView!)
        hitView!.backgroundColor = .clear
        
    }
    
    @objc func update() {
        //print("Updating!")
       // view.subviews.forEach({ $0.removeFromSuperview() })
        
        for subview in view.subviews {
            if subview is ScreenObject {
                
            }else{
                subview.removeFromSuperview()
            }
        }
        for index in 0..<ships.count {
            let v = UIView(frame: CGRect(origin: CGPoint(x: ships[index].point.x - (shipSize/2), y: ships[index].point.y - (shipSize/2)) , size: CGSize(width:shipSize,height: shipSize)))
            v.backgroundColor = .red
            self.view.addSubview(v)
            ships[index].point.y += fallRate
            
        }
        
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
                    hitView?.addSubview(v)
                    self.sendData(string: "foof")
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
            spawnTime = .now.addingTimeInterval(TimeInterval(2.5))
            ships.append(spaceShip(point: CGPoint(x: CGFloat.random(in:300...(self.view.frame.width - 300)), y: 0), rotation: 0.0, hit: false))
            //print(ships.count)
        }
        
        //remove fallen ships
        if let index:Int = ships.firstIndex(where: {$0.point.y > self.view.frame.height}) {
            ships.remove(at: index)
           // print("gone")
        }
        
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
                      
                      if(Date.now > self.missileShotTime){
                          self.missileShotTime = .now.addingTimeInterval(TimeInterval(0.2))
                          self.missiles.append(missile(point: CGPoint(x: self.personPos.x + 150, y: self.personPos.y), rotation: 0.0, hit: false))
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
        
        if let data = string.data(using: String.Encoding.utf8) {
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
        
        for observation in observations {
           // print(observation.debugDescription)
            DispatchQueue.main.async {
               // print(observation.boundingBox.midX * self.view.frame.width)
                self.personPos.x = (self.view.frame.width - (observation.boundingBox.midX * self.view.frame.width))-150
                
                self.personPos.y = self.view.frame.height - 100
            }
//            let hRect = try? observation.upperBodyOnly(
//            let thumbTip = try? observation.recognizedPoint(.thumbTip)
//            let indexTip = try? observation.recognizedPoint(.indexTip)
//            // ... extract other landmarks as needed
//            print(thumbTip.debugDescription)
        }
    }
    
    
    
  
    
}
                            

struct spaceShip{
    var point:CGPoint
    var rotation:CGFloat
    var hit:Bool
}

struct missile{
    var point:CGPoint
    var rotation:CGFloat
    var hit:Bool
}








    
 
    


