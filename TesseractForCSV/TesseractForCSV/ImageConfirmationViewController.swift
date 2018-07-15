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
    
    // exit confirmation page and return to camera
    @IBAction func retakePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confirmPressed(_ sender: Any) {
        // update UI
        configureUIForState(.loading)
        
        // run basic tesseract
        runBasicTesseract()
    }
    
    func presentCSVVC(forFile fileURL: URL) {
        // add fileURL and present view controller
        csvViewController.fileURL = fileURL
        self.present(csvViewController, animated: true, completion: nil)
    }
}

// MARK: -Vision Framework for Text Box Detection
extension ImageConfirmationViewController {
    
    func detectTextRectangles() {
        /*
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        let textRequest = VNDetectTextRectanglesRequest { (request, error) in
            // handle error
            if (error != nil) {
                print(error?.localizedDescription)
                return
            }
            
            guard let results = request.results as! [VNTextObservation] else {
                print("Results could not be converted")
            }
            
            
        }
        textRequest.reportCharacterBoxes = true
        */
        
        /*
        print(imageView.image?.imageOrientation.rawValue)
        
        
        // reorient image to the direction it was taken
        if let filteredImageCG = imageView.image?.cgImage {
            let orientedFilteredImage = UIImage(cgImage: filteredImageCG, scale: 1.0, orientation: (imageView.image?.imageOrientation)!)
    
        }
        let orientedImage = UIImage(cgImage: imageView.image as! CGImage, scale: 1.0, orientation: (imageView.image?.imageOrientation)!)
        */
        print("The image orientation in ICVC is \(image.imageOrientation.rawValue)")
        
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

// MARK: -Cropping Image and Running OCR on Text Boxes
extension ImageConfirmationViewController {
    
    /*
     * method to crop an image to a rectangle for use in OCR
     */
    func getCroppedImage(fromImage sourceImage: UIImage, forRect rect: CGRect) -> UIImage? {

        var sourceImageCGImage = sourceImage.orientedImage().cgImage
        
        var transformedRect = rect
        
        print(transformedRect)
        
        var transformSize = CGAffineTransform.identity
        transformSize = transformSize.scaledBy(x: image.size.width, y: -image.size.height)
        transformSize = transformSize.translatedBy(x: 0, y: -1)
        transformedRect = rect.applying(transformSize)
        print(transformedRect)
      
        let scaleUpPercentage: CGFloat = 0.05
        let scaledRect = transformedRect.insetBy(dx: -transformedRect.size.width * scaleUpPercentage, dy: -transformedRect.size.height * scaleUpPercentage)

        
        guard let croppedImage = sourceImageCGImage?.cropping(to: transformedRect) else {
            return nil
        }
    
        // reorient and return image
        return UIImage(cgImage: croppedImage).orientedImage()
    }
    
    /*
     * find the average character height and character width
     */
    func getAverageCharacterSize(forObservations observations: [VNTextObservation]) -> (CGFloat, CGFloat) {
        
        var heightSum: CGFloat = 0
        var widthSum: CGFloat = 0
        var characterCount: Int = 0
        
        for eachWord in observations {
            heightSum += eachWord.boundingBox.height
            
            for eachChar in eachWord.characterBoxes! {
                widthSum += eachChar.boundingBox.height
                characterCount += 1
            }
        }
        
        let avgHeight = heightSum / CGFloat(observations.count)
        let avgWidth = widthSum / CGFloat(characterCount)
        return (avgHeight, avgWidth)
    }
    
    func runBasicTesseract() {
    
         // run asynchronous call for OCR photo processing
         DispatchQueue.main.async {
            
            // run OCR on image and print the output text
            let ocrText = self.tesseractManager.runOCRonImage(inputImage: self.imageView.image!)
            
            let fileURL = self.createCSVFile(fromText: ocrText, forFile: DEFAULTFILENAME)
            self.presentCSVVC(forFile: fileURL)
            
            // TODO: not currently working
            // self.tesseractManager.getImageWithBlocks(inputImage: self.photoImage!)
        }
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
    
    func runAdvancedTesseract(forObservations observations: [VNTextObservation]) {
        
        let (charHeight, charWidth) = getAverageCharacterSize(forObservations: observations)
        print("the character height is \(charHeight)")
        var csvString = ""
        
        var previousLineY: CGFloat? = nil
        
        var wordsInRow: [String: CGFloat] = [:]
        
        for word in observations {
            print("iteration")
            // get cropped image
            let croppedImage = getCroppedImage(fromImage: image, forRect: word.boundingBox)
            
            // get words from cropped image
            var wordText =  self.tesseractManager.runOCRonLine(inputImage: croppedImage!)
            
            // clean text
            var cleanText = wordText
            cleanText = cleanText.replacingOccurrences(of: "\n", with: "")
            
            // process addition to csvString
            // TODO: fix spacing and delimitters
            if (previousLineY != nil) {
                if(abs(word.boundingBox.midY - previousLineY!) < charHeight) {
                    // word is part of exisitng row
                    wordsInRow[cleanText] = word.boundingBox.midX
                } else {
                    // word is part of new row
                    previousLineY = word.boundingBox.midY
                    
                    csvString += sortRowDictionary(forRow: wordsInRow, withDelimiter: String(DELIMITER)) + "\n"
                    
                    // clear data from existing
                    wordsInRow = [:]
                    wordsInRow[cleanText] = word.boundingBox.midX
                }
            } else {
                // handle first case
                previousLineY = word.boundingBox.midY
                wordsInRow[cleanText] = word.boundingBox.midX
            }
        }
        
        // append last row to csvString
        csvString += sortRowDictionary(forRow: wordsInRow, withDelimiter: String(DELIMITER))
 
        // run text conversion
        let converter = TextToCSVConverter.sharedInstance
        
        let refinedString = converter.convertTextToCSVString(forText: csvString, withConversionMethod: .guesstimate)
        
        // save CSV file and get file url
        let url = converter.convertCSVStringToFile(forString: refinedString, withFileName: DEFAULTFILENAME)
        csvViewController.updateFileURL(withFileURL: url!)
    }
    
    /*
     * helper method that takes a dictionary of unsorted words in the same row and orders them into a String
     */
    private func sortRowDictionary(forRow row: [String: CGFloat], withDelimiter delimiter: String) -> String {
        
        let sortedDictionary = row.sorted { $0.1 < $1.1 }
        
        var rowStr = ""
        for (key, value) in sortedDictionary {
            rowStr += key + delimiter
        }
        
        // return string after removing extra delimiter at the end
        return String(rowStr.dropLast())
    }
}


