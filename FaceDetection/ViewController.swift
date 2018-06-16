//
//  ViewController.swift
//  FaceDetection
//
//  Created by André Vellori on 16/06/2018.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            DispatchQueue.main.async {
                self.start()
            }
            
        })
        
        
    }
    var facesRect = [Int: CGRect]() {
        didSet {
            DispatchQueue.main.async {
                self.view.setNeedsLayout()
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        
        doFace(faces: facesRect)
        super.viewWillLayoutSubviews()
    }
    
    func doFace(faces: [Int: CGRect]) {
        var allMyViews = [Int]() + blurViews.keys
        
        for face in faces.keys {
            if blurViews[face] == nil {
                let aView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                aView.backgroundColor = UIColor.white
                blurViews[face] = aView
                aView.addSubview(UIVisualEffectView(effect: UIBlurEffect(style: .extraLight)))
                aView.layer.cornerRadius = 20
                aView.clipsToBounds = true
                view.addSubview(aView)
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                aView.addSubview(label)
                label.text = "\(face)"
                label.centerXAnchor.constraint(equalTo: aView.centerXAnchor).isActive = true
                label.centerYAnchor.constraint(equalTo: aView.centerYAnchor).isActive = true
                
            }
            blurViews[face]?.frame = self.previewView.convert( faces[face]!, to: self.view)
            if let index = allMyViews.index(of: face) {
                allMyViews.remove(at: index)
            }
        }
        
        allMyViews.forEach { (aViewID) in
            let aView = blurViews[aViewID]
            aView?.removeFromSuperview()
            blurViews[aViewID] = nil
            print(aViewID)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var defaultVideoDevice: AVCaptureDevice?
    let session = AVCaptureSession()
    let metadataOutput = AVCaptureMetadataOutput()
    let metadataObjectsQueue = DispatchQueue(label: "metadata objects queue", attributes: [], target: nil)
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    @IBOutlet var previewView: UIView!
    
    @IBOutlet var rollLabel: UILabel!
    @IBOutlet var yawLabel: UILabel!
    
    var blurViews = [Int: UIView]()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = previewView.bounds
    }
}


extension ViewController {
    func start() {
        guard let device = AVCaptureDevice.devices().filter({ $0.position == .front })
            .first else {
                fatalError("No front facing camera found")
        }
        let frontCameraDevice = device
        let videoDeviceInput = try! AVCaptureDeviceInput(device: frontCameraDevice)
        session.addInput(videoDeviceInput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataObjectsQueue)
        session.addOutput(metadataOutput)
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewView.layer.addSublayer(videoPreviewLayer!)
        print(metadataOutput.availableMetadataObjectTypes)
        metadataOutput.metadataObjectTypes = [.face]
        session.startRunning()
        videoPreviewLayer?.frame = previewView.bounds
    }
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let faces = metadataObjects.reduce([Int: CGRect]()) { (result, object) -> [Int: CGRect] in
            guard let face = object as? AVMetadataFaceObject else {
                return result
            }
            let frame = (self.videoPreviewLayer?.layerRectConverted(fromMetadataOutputRect: face.bounds))!
            
            var myResult = result
            myResult[face.faceID] = frame
            return myResult
        }
        
        facesRect = faces
        
    }
}

