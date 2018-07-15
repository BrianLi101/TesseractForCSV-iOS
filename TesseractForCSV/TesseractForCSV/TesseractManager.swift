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

class TesseractManager: NSObject {
    
    // MARK: - Singleton Instance
    static var sharedInstance: TesseractManager = TesseractManager()
    
    // MARK: - Properties
    private var tesseract: G8Tesseract!
    private var image: UIImage!
    
    // init TesseractManager sharedInstance
    private override init() {
        super.init()
        
        // set default language to english
        tesseract = G8Tesseract(language:"eng")
        
        // uncomment line below to change language
        // tesseract.language = "eng+ita"
        
        // set delegate to self
        tesseract.delegate = self
        
        // determines which models to use for OCR
        tesseract.engineMode = .tesseractCubeCombined
        
        // allow recognition of only numbers, letters, and basic symbols
        tesseract.charWhitelist = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.,()$-+"
    }
    
    /*
     * method that runs OCR on an image of a block of text
     */
    func runOCRonImage(inputImage: UIImage) -> String {
        // set the segmentation mode to auto
        tesseract.pageSegmentationMode = .auto
        
        // update shared image to be the inputImage
        image = inputImage

        // set the inputImage for recognition
        tesseract.image = image
        
        // comment out line below to use raw image without GPUImage AdaptiveThreshold filter
        tesseract.image = processImageWithAdaptiveThresholdFilter(forImage: image)
        
        // run processing on image for text recognition
        tesseract.recognize()
        
        return tesseract.recognizedText
    }
    
    /*
     * method that runs OCR on an image of a single line of text
     * (more accurate than the block of text implementation)
     */
    func runOCRonLine(inputImage: UIImage) -> String {
        // set the segmentation mode to recognize a single line
        tesseract.pageSegmentationMode = .singleLine
        
        // update shared image to be the inputImage
        image = inputImage
        
        // set the inputImage for recognition
        tesseract.image = image
        
        // comment out line below to use raw image without GPUImage AdaptiveThreshold filter
        tesseract.image = processImageWithAdaptiveThresholdFilter(forImage: image)
        
        // run processing on image for text recognition
        tesseract.recognize()
        
        return tesseract.recognizedText
    }
    
}

// MARK: -G8TesseractDelegate
extension TesseractManager: G8TesseractDelegate {
    
    /*
     * delegate method that is called to get image for OCR processing
     */
    func preprocessedImage(for tesseract: G8Tesseract?, sourceImage: UIImage?) -> UIImage? {
        
        // bypasses tesseract's internal threshold image processing to return whatever image was supplied
        return sourceImage
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
     * returns black and white image with filtering through adaptive threshold filter
     */
    func processImageWithAdaptiveThresholdFilter(forImage inputImage: UIImage) -> UIImage {
        // initialize adaptive threshold filter
        let stillImageFilter = AdaptiveThreshold()
        
        // adjust this to tweak the blur radius of the filter, defaults to 4.0
        stillImageFilter.blurRadiusInPixels = 750.0
        
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
