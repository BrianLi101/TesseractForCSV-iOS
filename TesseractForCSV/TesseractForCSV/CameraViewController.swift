//
//  CameraViewController.swift
//  TesseractForCSV
//
//  Created by Brian Li on 7/5/18.
//  Copyright © 2018 Brian Li. All rights reserved.
//

import UIKit
import AVFoundation
import WebKit
import Vision

class CameraViewController: UIViewController {

    var captureSession: AVCaptureSession = AVCaptureSession()
    var capturePhotoOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var photoImage: UIImage?
    let tesseractManager = TesseractManager.sharedInstance
    
    var captureVidoeDataOutput: AVCaptureVideoDataOutput?
    var vnRequests = [VNRequest]()
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var captureButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // intiate the capture session
        setUpCaptureSession()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // start running capture session
        captureSession.startRunning()
        
        startTextDetection()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // update preview layer frame
        previewLayer?.frame = cameraView.bounds
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // close out capture session to conserve energy
        captureSession.stopRunning()
    }
    
    func setUpCaptureSession() {
        
        
        // setup capture session for camera interface
        captureSession.sessionPreset = .hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: .video)
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera!)
            
            if (captureSession.canAddInput(input)) {
                captureSession.addInput(input)
                
                // capture output for still image
                capturePhotoOutput = AVCapturePhotoOutput()
                captureSession.addOutput(capturePhotoOutput!)
                
                // capture output for video frame by frame processing
                captureVidoeDataOutput = AVCaptureVideoDataOutput()
                captureVidoeDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                captureVidoeDataOutput?.setSampleBufferDelegate(self as? AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
                captureSession.addOutput(captureVidoeDataOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = .resizeAspect
                previewLayer?.connection?.videoOrientation = .portrait
                cameraView.layer.addSublayer(previewLayer!)
            }
        } catch {
            print("Error: could not access camera")
        }
    }
    
    @IBAction func takePhotoClicked(_ sender: Any) {
        
        // call function to take photo
        capturePhoto()
    }
    
    /*
     * method to display webView of contents in file path
     */
    func displayContentsOfCSVFile(forFile fileURL: URL) {
        
        // load file in webView to verify accuracy
        //let webView = WKWebView(frame: self.view.bounds)
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
        self.view.addSubview(webView)
    }
    
    /*
     * method to test if TextToCSVConvertor is working
     */
    func testTextToCSVConverterDefault() {
        
        // default text to convert to CSV
        let text = """
Quarter Revenue
1st $100000
2nd $98000
3rd $82000
4th $120000
"""
        // run text conversion
        let converter = TextToCSVConverter.sharedInstance
        let csvText = converter.convertTextToCSVString(forText: text, withConversionMethod: .basic)
        
        // save CSV file and get file url
        let url = converter.convertCSVStringToFile(forString: csvText, withFileName: "Test")
        
        // load file in webView to verify accuracy
        let webView = WKWebView(frame: self.view.bounds)
        webView.loadFileURL(url!, allowingReadAccessTo: url!)

        self.view.addSubview(webView)
    }
}

// MARK: -AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    /*
     * method to set up photo capture settings before calling photoOutput
     */
    func capturePhoto() {

        // set up photo capture settings and prepare for taking photo
        let captureSettings = AVCapturePhotoSettings()
        let previewPixelType = captureSettings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160]
        captureSettings.previewPhotoFormat = previewFormat
        self.capturePhotoOutput?.capturePhoto(with: captureSettings, delegate: self)
        
    }
    
    /*
     * AVCapturePhotoCaptureDelegate method to capture photo
     */
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        // process error
        if let error = error {
            print(error.localizedDescription)
        }
        
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            // update variable with data from captured image
            photoImage = UIImage(data: dataImage)
            
            DispatchQueue.main.async {
                // intantiate view controller to present user with confirmation screen
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let imageConfirmationViewController = storyBoard.instantiateViewController(withIdentifier: "ImageConfirmationViewController") as! ImageConfirmationViewController
                imageConfirmationViewController.image = self.photoImage!
                
                self.present(imageConfirmationViewController, animated: true, completion: nil)
            }
            
        }
        
    }
    
}

// MARK: -Vision Framework Implementation for Text Detection
// text detection boxes implementation found via https://github.com/appcoda/TextDetection
extension CameraViewController {
    func startTextDetection() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        textRequest.reportCharacterBoxes = true
        self.vnRequests = [textRequest]
    }
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            print("no result")
            return
        }

        let result = observations.map({$0 as? VNTextObservation})
        
        DispatchQueue.main.async() {
            self.cameraView.layer.sublayers?.removeSubrange(1...)
            for region in result {
                guard let rg = region else {
                    continue
                }
                
                self.highlightWord(box: rg)
                
                if let boxes = region?.characterBoxes {
                    for characterBox in boxes {
                        self.highlightLetters(box: characterBox)
                    }
                }
            }
        }
    }
    
    func highlightWord(box: VNTextObservation) {
        guard let boxes = box.characterBoxes else {
            return
        }
        
        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < maxX {
                maxX = char.bottomLeft.x
            }
            if char.bottomRight.x > minX {
                minX = char.bottomRight.x
            }
            if char.bottomRight.y < maxY {
                maxY = char.bottomRight.y
            }
            if char.topRight.y > minY {
                minY = char.topRight.y
            }
        }
        
        let xCord = maxX * cameraView.frame.size.width
        let yCord = (1 - minY) * cameraView.frame.size.height
        let width = (minX - maxX) * cameraView.frame.size.width
        let height = (minY - maxY) * cameraView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor
        
        cameraView.layer.addSublayer(outline)
    }
    
    func highlightLetters(box: VNRectangleObservation) {
        let xCord = box.topLeft.x * cameraView.frame.size.width
        let yCord = (1 - box.topLeft.y) * cameraView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * cameraView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * cameraView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 1.0
        outline.borderColor = UIColor.blue.cgColor
        
        cameraView.layer.addSublayer(outline)
    }
}

// MARK: -AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.vnRequests)
        } catch {
            print(error)
        }
    }
}
