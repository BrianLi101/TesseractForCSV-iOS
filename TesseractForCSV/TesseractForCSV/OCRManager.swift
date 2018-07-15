//
//  OCRManager.swift
//  TesseractForCSV
//
//  Created by Brian Li on 7/15/18.
//  Copyright © 2018 Brian Li. All rights reserved.
//

import Foundation
import UIKit
import Vision

class OCRManager {
    
    private enum TesseractType {
        case basic, advanced
    }
    
    // MARK: - Singleton Instance
    static var sharedInstance: OCRManager = OCRManager()
    
    // sharedInstances of TesseractManager and TextToCSVConverter
    private let tesseractManager = TesseractManager.sharedInstance
    private let converter = TextToCSVConverter.sharedInstance
    
    private init() {
        
    }
    
    /*
     * takes text from OCR, processes it with column guessing, and returns the url of the newly created csv file
     */
    private func createCSVFile(fromText text: String, forFile fileName: String, withType type: TesseractType) -> URL? {
        
        switch (type) {
        case .basic:
            print("Running basic Tesseract")
            
            // additional step of running initial cleaning on block Tesseract text
            let cleanedText = converter.cleanTesseractText(forText: text)
            
            // modify rows based on average columns and get the csv string
            let csvText = converter.convertTextToCSVString(forText: cleanedText, withConversionMethod: .guesstimate)
            
            // save CSV file and get file url
            let url = converter.convertCSVStringToFile(forString: csvText, withFileName: fileName)
            
            return url!
            
        case .advanced:
            print("Running advanced Tesseract")
            
            // modify rows based on average columns and get the csv string
            let csvText = converter.convertTextToCSVString(forText: text, withConversionMethod: .guesstimate)
            
            // save CSV file and get file url
            let url = converter.convertCSVStringToFile(forString: csvText, withFileName: fileName)
            
            return url!
            
        default:
            print("Error: type not recognized")
            
            return nil
        }
    }
}

// MARK: -Simple Tesseract OCR
extension OCRManager {
    /*
     * method called from outside to run basic Tesseract OCR on entire image at once
     */
    func runBasicTesseractOCR(onImage sourceImage: UIImage, completionHandler: @escaping(_ success: Bool, _ responseURL: URL)->()) {
        
        // run OCR on image and print the output text
        let ocrText = self.tesseractManager.runOCRonImage(inputImage: sourceImage)
        
        let fileURL = self.createCSVFile(fromText: ocrText, forFile: DEFAULTFILENAME, withType: .basic)
        
        // call completion handler
        completionHandler(true, fileURL!)
    }
}

// MARK: -Advanced Tesseract OCR
extension OCRManager {
    /*
     * method called from outside to run advanced Tesseract OCR on a word-by-word basis
     */
    func runAdvancedTesseractOCR(onImage sourceImage: UIImage, forObservations observations: [VNTextObservation], completionHandler: @escaping(_ success: Bool, _ responseURL: URL)->()) {
        
        // get the average character height and width to determine where words belong relative to each other
        let (charHeight, charWidth) = getAverageCharacterSize(forObservations: observations)
        
        var csvString = ""
        
        // variable is updated each time a word appears at a y position more than a line height away from the previous line
        var previousLineY: CGFloat? = nil
        
        var wordsInRow: [String: CGFloat] = [:]
        
        for word in observations {
            print("iteration")
            // get cropped image
            let croppedImage = getCroppedImage(fromImage: sourceImage, forRect: word.boundingBox)
            
            // get words from cropped image
            var wordText =  self.tesseractManager.runOCRonLine(inputImage: croppedImage!)
            
            // clean text with basic removal
            var cleanText = wordText
            cleanText = cleanText.replacingOccurrences(of: "\n", with: "")
            
            // process addition to csvString
            if (previousLineY != nil) {
                if(abs(word.boundingBox.midY - previousLineY!) < charHeight) {
                    // word is part of exisitng row
                    wordsInRow[cleanText] = word.boundingBox.midX
                } else {
                    // word is part of new row
                    previousLineY = word.boundingBox.midY
                    
                    csvString += sortRowDictionary(forRow: wordsInRow, withDelimiter: String(DELIMITER)) + "\n"
                    
                    // clear data from existing row
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
        
        // process text and convert to csv file
        let fileURL = self.createCSVFile(fromText: csvString, forFile: DEFAULTFILENAME, withType: .advanced)
        
        // call completion handler
        completionHandler(true, fileURL!)
    }
    
    /*
     * method to crop an image to a rectangle for use in OCR
     */
    private func getCroppedImage(fromImage sourceImage: UIImage, forRect rect: CGRect) -> UIImage? {
        
        var sourceImageCGImage = sourceImage.orientedImage().cgImage
        
        var transformedRect = rect
        
        // run transformations on rectangle to scale to cg image size
        var transformSize = CGAffineTransform.identity
        transformSize = transformSize.scaledBy(x: sourceImage.size.width, y: -sourceImage.size.height)
        transformSize = transformSize.translatedBy(x: 0, y: -1)
        transformedRect = rect.applying(transformSize)
        
        // uncomment lines below to add additional padding around word boxes
        //let scaleUpPercentage: CGFloat = 0.05
        //let scaledRect = transformedRect.insetBy(dx: -transformedRect.size.width * scaleUpPercentage, dy: -transformedRect.size.height * scaleUpPercentage)
        
        // safely crop image
        guard let croppedImage = sourceImageCGImage?.cropping(to: transformedRect) else {
            return nil
        }
        
        // reorient and return image
        return UIImage(cgImage: croppedImage).orientedImage()
    }
    
    /*
     * find the average character height and character width
     */
    private func getAverageCharacterSize(forObservations observations: [VNTextObservation]) -> (CGFloat, CGFloat) {
        
        var heightSum: CGFloat = 0
        var widthSum: CGFloat = 0
        var characterCount: Int = 0
        
        // iterate through all words to get average word height
        for eachWord in observations {
            heightSum += eachWord.boundingBox.height
            
            // iterate through all characters to get average character width
            for eachChar in eachWord.characterBoxes! {
                widthSum += eachChar.boundingBox.height
                characterCount += 1
            }
        }
        
        let avgHeight = heightSum / CGFloat(observations.count)
        let avgWidth = widthSum / CGFloat(characterCount)
        return (avgHeight, avgWidth)
    }
    
    /*
     * helper method that takes a dictionary of unsorted words in the same row and orders them into a String based on location along x axis
     */
    private func sortRowDictionary(forRow row: [String: CGFloat], withDelimiter delimiter: String) -> String {
        
        // sorts dictionary by value of location along x axis
        let sortedDictionary = row.sorted { $0.1 < $1.1 }
        
        var rowStr = ""
        for (key, value) in sortedDictionary {
            rowStr += key + delimiter
        }
        
        // return string after removing extra delimiter at the end
        rowStr.remove(at: rowStr.index(before: rowStr.endIndex))
        return rowStr
    }
}

