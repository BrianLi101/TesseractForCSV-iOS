//
//  TextToCSVConverter.swift
//  TesseractForCSV
//
//  Created by Brian Li on 7/7/18.
//  Copyright © 2018 Brian Li. All rights reserved.
//

import Foundation

class TextToCSVConverter {
    
    enum ConversionMethod {
        case basic
    }
    
    // MARK: - Singleton Instance
    static var sharedInstance: TextToCSVConverter = TextToCSVConverter()
    
    private init() {
        
    }
    
    /*
     * method to clean the OCR recognized text to make conversion to CSV easier
     */
    private func cleanText(forText text: String) -> String {
        var cleanedText = text
        
        // remove multiple new lines
        cleanedText = cleanedText.replacingOccurrences(of: "\n\n", with: "\n")
        
        return cleanedText
    }
    
    /*
     * method to take csvString and save it as CSV file in documents directory
     */
    func convertCSVStringToFile(forString csvString: String, withFileName fileName: String) -> URL? {
        // initiate fileURL to return as nil
        var fileURL: URL? = nil
        
        // attempt to create and save file with error handling
        do {
            // get document folder path
            let fileManager = FileManager.default
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            
            // create fileURL using fileName
            fileURL = documentDirectory.appendingPathComponent(fileName + ".csv")
            
            // write data to file
            try csvString.write(to: fileURL!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Error: failure to save data\n")
        }
        
        return fileURL
    }
    
    /*
     * run conversion of text to csvString with a selected method
     */
    func convertTextToCSVString(forText text: String, withConversionMethod method: ConversionMethod) -> String {
        let rows: [String] = text.components(separatedBy: "\n")
        
        var csvString: String!
        
        switch method {
        case .basic:
            print("Using basic conversion")
            csvString = textToCSVBasic(forRows: rows)
        default:
            print("Using default conversion")
            csvString = ""
        }
        
        return csvString
    }
    
    /*
     * basic conversion with no accounting for column and row accuracy
     */
    private func textToCSVBasic(forRows rows: [String]) -> String {
        var csvString = ""
        
        for row in rows {
            // add "" around numbers and words to escape for the use of commas
            csvString += row.replacingOccurrences(of: " ", with: ",")
            csvString += "\n"
        }
        
        return csvString
    }
}
