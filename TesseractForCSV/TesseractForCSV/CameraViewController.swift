//
//  CameraViewController.swift
//  TesseractForCSV
//
//  Created by Brian Li on 7/5/18.
//  Copyright © 2018 Brian Li. All rights reserved.
//

import UIKit
import AVFoundation

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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // update preview layer frame
        previewLayer?.frame = cameraView.bounds
    }
    
    
    @IBAction func takePhotoClicked(_ sender: Any) {
        
        // call function to take photo
        capturePhoto()
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
                // run OCR on image and print the output text
                self.tesseractManager.runOCRonImage(inputImage: self.photoImage!)
                
                // update image view with processed black and white image
                imageView.image = self.tesseractManager.processImageWithAdaptiveThresholdFilter(forImage: self.photoImage!)
                
                // not currently working
                // self.tesseractManager.getImageWithBlocks(inputImage: self.photoImage!)
            }
            
        }
        
    }
    
}


