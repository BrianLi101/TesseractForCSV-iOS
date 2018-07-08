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
        case basic, guesstimate
    }
    
    // MARK: - Singleton Instance
    static var sharedInstance: TextToCSVConverter = TextToCSVConverter()
    
    private init() {
        
    }
    
    /*
     * method to clean the OCR recognized text to make conversion to CSV easier
     */
    func cleanTesseractText(forText text: String) -> String {
        print("original text is")
        dump(text)
        var cleanedText = text
        
        // remove multiple new lines
        cleanedText = cleanedText.replacingOccurrences(of: "\n\n", with: "\n")
        
        // remove randomly recognized periods
        cleanedText = cleanedText.replacingOccurrences(of: " . ", with: " ")
        cleanedText = cleanedText.replacingOccurrences(of: ".\n", with: "\n")
        
        // remove randomly placed commas
        cleanedText = cleanedText.replacingOccurrences(of: " , ", with: " ")
        
        // remove extra spaces
        cleanedText = cleanedText.replacingOccurrences(of: "    ", with: " ")
        cleanedText = cleanedText.replacingOccurrences(of: "   ", with: " ")
        cleanedText = cleanedText.replacingOccurrences(of: "  ", with: " ")
        
        // remove spaces on or before new lines
        cleanedText = cleanedText.replacingOccurrences(of: " \n", with: "\n")
        cleanedText = cleanedText.replacingOccurrences(of: "\n ", with: "\n")

        print("cleaned text is")
        dump(cleanedText)
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
        case .guesstimate:
            print("Using row guessing conversion")
            print(guessColumnNumber(forRows: rows))
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
            // TODO: add "" around numbers and words to escape for the use of commas
            csvString += row.replacingOccurrences(of: " ", with: ",")
            csvString += "\n"
        }
        
        return csvString
    }
    
    private func textToCSVGuesstimate(forRows rows: [String], withColumnNumber columns: Int) -> String {
        var csvString = ""
        
        for row in rows {
            let spaces = getOccurrencesOf(of: " ", inString: row)
            
            if spaces == columns {
                // columns in row are correct
                
                // TODO: add "" around numbers and words to escape for the use of commas
                csvString += row.replacingOccurrences(of: " ", with: ",")
                csvString += "\n"
            } else if spaces > columns {
                // columns in row are too many
                var strArray = row.split(separator: " ")
                
                // not too sure how to handle this yet
            } else {
                // columns in row are too few
                
                // TODO: add "" around numbers and words to escape for the use of commas
                csvString += row.replacingOccurrences(of: " ", with: ",")
                csvString += "\n"
            }
            
            
        }
        
        return csvString
    }
    
    /*
     * method to guess the number of columns by averaging and rounding blank spaces for all rows
     */
    private func guessColumnNumber(forRows rows: [String]) -> Int {
        var sum: Int = 0
        for row in rows {
            sum += getOccurrencesOf(of: " ", inString: row)
        }
        print("Sum is \(sum) for \(rows.count) rows")
        var avg: Double = Double(sum) / Double(rows.count)
        print(avg)
        avg.round(.toNearestOrEven)
        print(avg)
        print(Int(avg))
        return Int(avg)
    }
    
    /*
     * helper method to count the occurrences of characters (spaces) in a string
     */
    private func getOccurrencesOf(of char: Character, inString str: String) -> Int {
        
        var count: Int = 0
        for each in str {
            if each == char {
                count += 1
            }
        }
        print("Count of spaces for \(str) is \(count)")
        return count
    }
}
