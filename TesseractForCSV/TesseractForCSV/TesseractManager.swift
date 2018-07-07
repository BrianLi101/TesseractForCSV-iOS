//
//  TesseractManager.swift
//  TesseractForCSV
//
//  Created by Brian Li on 7/6/18.
//  Copyright © 2018 Brian Li. All rights reserved.
//

import Foundation
import TesseractOCR
import GPUImage

class TesseractManager {
    
    // MARK: - Singleton Instance
    static var sharedInstance: TesseractManager = TesseractManager()
    
    // MARK: - Properties
    private var tesseract: G8Tesseract!
    private var image: UIImage!
    
    // setup TesseractManager sharedInstance
    private init() {
        // set default language to english
        tesseract = G8Tesseract(language:"eng")
        
        //tesseract.engineMode = .tesseractCubeCombined
        //tesseract.language = "eng+ita"
        //tesseract.delegate = self
        //tesseract.charWhitelist = "01234567890"
        
        // allow recognition of only numbers, letters, and basic symbols
        tesseract.charWhitelist = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.,()"
        
        //tesseract.image = image
    }
    
    /*
     * method that runs OCR and prints text from
     */
    func runOCRonImage(inputImage: UIImage) -> String {
        // update shared image to be the inputImage
        image = inputImage

        // set the inputImage for recognition
        tesseract.image = image
        
        // comment out line below to use raw image without GPUImage AdaptiveThreshold filter
        tesseract.image = processImageWithAdaptiveThresholdFilter(forImage: image)
        
        // run processing on image for text recognition
        tesseract.recognize()
        
        print(tesseract.recognizedText)
        
        return tesseract.recognizedText
    }
    
    /*
     * incomplete, not working method
     */
    func getImageWithBlocks(inputImage: UIImage) -> UIImage {
        // You could retrieve more information about recognized text with that methods:
        
        var lineBlocks = tesseract.recognizedBlocks(by: .textline)
        
        var paragraphBlocks = tesseract.recognizedBlocks(by: .paragraph)
        
        var characterChoices = tesseract.characterChoices
        
        var imageWithBlocks: UIImage? = tesseract.image(withBlocks: characterChoices, drawText: true, thresholded: false)
        
        return imageWithBlocks!
    }
    
    func progressImageRecognition(for tesseract: G8Tesseract?) {
        print("progress: \(UInt(tesseract?.progress ?? 0))")
    }
    
    func shouldCancelImageRecognitionForTesseract(tesseract: G8Tesseract!) -> Bool {
        // return true if you need to interrupt tesseract before it finishes
        return false
    }
}

// MARK: -GPUImage
extension TesseractManager {
    
    /*
     * method using GPUImage framework to process the image for better OCR results
     * returns black and white image with filtering
     */
    func processImageWithAdaptiveThresholdFilter(forImage inputImage: UIImage) -> UIImage {
        // initialize adaptive threshold filter
        let stillImageFilter = AdaptiveThreshold()
        
        // adjust this to tweak the blur radius of the filter, defaults to 4.0
        stillImageFilter.blurRadiusInPixels = 4.0
        
        // retrieve the filtered image from the filter
        var filteredImage = inputImage.filterWithOperation(stillImageFilter)
        
        // reorient image to the direction it was taken
        if let filteredImageCG = filteredImage.cgImage {
            let orientedFilteredImage = UIImage(cgImage: filteredImageCG, scale: 1.0, orientation: inputImage.imageOrientation)
            return orientedFilteredImage
        }
        
        return filteredImage
    }
}
