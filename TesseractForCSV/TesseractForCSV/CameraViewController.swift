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

class CameraViewController: UIViewController {

    var captureSession: AVCaptureSession?
    var capturePhotoOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var photoImage: UIImage?
    let tesseractManager = TesseractManager.sharedInstance
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var captureButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // setup capture session for camera interface
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: .video)
    

        do {
            let input = try AVCaptureDeviceInput(device: backCamera!)

            if (captureSession?.canAddInput(input))! {
                captureSession?.addInput(input)
                
                capturePhotoOutput = AVCapturePhotoOutput()
                captureSession?.addOutput(capturePhotoOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer?.videoGravity = .resizeAspect
                previewLayer?.connection?.videoOrientation = .portrait
                cameraView.layer.addSublayer(previewLayer!)
                captureSession?.startRunning()
            }
        } catch {
            print("Error: could not access camera")
        }
        
        //testTextToCSVConverter()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // update preview layer frame
        previewLayer?.frame = cameraView.bounds
        
        self.view.bringSubview(toFront: captureButton)
    }
    
    
    @IBAction func takePhotoClicked(_ sender: Any) {
        
        // call function to take photo
        capturePhoto()
    }
    
    func createCSVFile(fromText text: String, forFile fileName: String) -> URL {
        
        // run text conversion
        let converter = TextToCSVConverter.sharedInstance
        let cleanedText = converter.cleanTesseractText(forText: text)

        let csvText = converter.convertTextToCSVString(forText: cleanedText, withConversionMethod: .guesstimate)
        
        // save CSV file and get file url
        let url = converter.convertCSVStringToFile(forString: csvText, withFileName: fileName)
        
        return url!
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
        
        //
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            // update variable with data from captured image
            photoImage = UIImage(data: dataImage)
            
            // create image view and display the captured photo
            var imageView = UIImageView(frame: self.view.bounds)
            imageView.image = photoImage
            self.view.addSubview(imageView)
            
            // run asynchronous call for OCR photo processing
            DispatchQueue.main.async {
                
                // update image view with processed black and white image
                imageView.image = self.tesseractManager.processImageWithAdaptiveThresholdFilter(forImage: self.photoImage!)
                
                // run OCR on image and print the output text
                let ocrText = self.tesseractManager.runOCRonImage(inputImage: self.photoImage!)
                
                let fileURL = self.createCSVFile(fromText: ocrText, forFile: "Test")
                self.displayContentsOfCSVFile(forFile: fileURL)
                
                // not currently working
                // self.tesseractManager.getImageWithBlocks(inputImage: self.photoImage!)
            }
            
        }
        
    }
    
}


