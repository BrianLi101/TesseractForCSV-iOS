//
//  ImageConfirmationViewController.swift
//  TesseractForCSV
//
//  Created by Brian Li on 7/14/18.
//  Copyright © 2018 Brian Li. All rights reserved.
//

import UIKit
import Vision

let DEFAULTFILENAME: String = "CSVFile"

class ImageConfirmationViewController: UIViewController {

    private enum ScreenState {
        case `init`, normal, loading
    }
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var retakeButton: UIBarButtonItem!
    @IBOutlet var confirmButton: UIBarButtonItem!
    
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    var image: UIImage = UIImage()
    
    var textBoxes: [VNTextObservation] = []
    
    let tesseractManager = TesseractManager.sharedInstance
    
    let ocrManager = OCRManager.sharedInstance
    
    var csvViewController: CSVViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // instantiate child view controller to be presented after OCR complete
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        csvViewController = storyBoard.instantiateViewController(withIdentifier: "CSVViewController") as! CSVViewController
        
        // configure UI
        configureUIForState(.init)
        configureUIForState(.loading)
        
        DispatchQueue.main.async {
            // update image view with processed black and white image
            self.imageView.image = self.tesseractManager.processImageWithAdaptiveThresholdFilter(forImage: self.image)
            
            self.detectTextRectangles()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func configureUIForState(_ state: ScreenState) {
        switch (state) {
        case .init:
            print("Init")
            imageView.image = image
            
            // set navigation bar to clear
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationBar.shadowImage = UIImage()
            navigationBar.isTranslucent = true
            navigationBar.backgroundColor = .clear
            
            activityIndicator.center = self.view.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.color = .black
            self.view.addSubview(activityIndicator)
            
        case .normal:
            print("Normal")
            
            activityIndicator.stopAnimating()
            
            confirmButton.isEnabled = true
        case .loading:
            print("Loading")
            
            activityIndicator.startAnimating()
            
            confirmButton.isEnabled = false
        default:
            print("Invalid ScreenState")
        }
    }
    
    /*
     * method that exits confirmation page and returns to camera
     */
    @IBAction func retakePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // run basic ocr
    @IBAction func confirmPressed(_ sender: Any) {
        // update UI
        configureUIForState(.loading)
        
        // run basic tesseract with completion handler
        ocrManager.runBasicTesseractOCR(onImage: self.imageView.image!) { (success, responseURL) in
            
            // present created file if successful
            if (success) {
                self.presentCSVVC(forFile: responseURL)
            }
        }
    }
    
    /*
     * method that presents the CSVViewController with the file loaded in the view
     */
    func presentCSVVC(forFile fileURL: URL) {
        // add fileURL and present view controller
        csvViewController.fileURL = fileURL
        self.present(csvViewController, animated: true, completion: nil)
    }
}

// MARK: -Vision Framework for Text Box Detection
// text detection boxes implementation found via https://github.com/appcoda/TextDetection
extension ImageConfirmationViewController {
    
    func detectTextRectangles() {

        let orientedImage = UIImage(cgImage: self.image.cgImage!, scale: 1.0, orientation: image.imageOrientation)
        
        // TODO: revise image orientation property
        let handler = VNImageRequestHandler(cgImage: orientedImage.cgImage!, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: [VNImageOption: Any]())
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        textRequest.reportCharacterBoxes = true
        
        do {
            try handler.perform([textRequest])
        } catch {
            print("Request error")
        }
    }
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        // handle error
        if (error != nil) {
            print(error?.localizedDescription as! String)
            return
        }
        
        guard let observations = request.results else {
            print("no result")
            return
        }
        
        textBoxes = observations.map({($0 as? VNTextObservation)!})
        
        DispatchQueue.main.async() {
            
            self.imageView.layer.sublayers?.removeSubrange(1...)
            for region in self.textBoxes {
                
                self.highlightWord(box: region)
                
                if let boxes = region.characterBoxes {
                    for characterBox in boxes {
                        self.highlightLetters(box: characterBox)
                    }
                }
            }
            
            // set normal UI after text boxes are drawn
            self.configureUIForState(.normal)
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
        
        let xCord = maxX * imageView.frame.size.width
        let yCord = (1 - minY) * imageView.frame.size.height
        let width = (minX - maxX) * imageView.frame.size.width
        let height = (minY - maxY) * imageView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        print(outline.frame)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor
        
        imageView.layer.addSublayer(outline)
    }
    
    func highlightLetters(box: VNRectangleObservation) {
        let xCord = box.topLeft.x * imageView.frame.size.width
        let yCord = (1 - box.topLeft.y) * imageView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * imageView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * imageView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 1.0
        outline.borderColor = UIColor.blue.cgColor
        
        imageView.layer.addSublayer(outline)
    }
}

