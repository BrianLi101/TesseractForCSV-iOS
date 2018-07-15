//
//  TextToCSVConverter.swift
//  TesseractForCSV
//
//  Created by Brian Li on 7/7/18.
//  Copyright © 2018 Brian Li. All rights reserved.
//

import Foundation

let DELIMITER: Character = "@"

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
        cleanedText = cleanedText.replacingOccurrences(of: " . ", with: " ") // CONCERN: missing data is represented by periods in some statistical data sets
        cleanedText = cleanedText.replacingOccurrences(of: ".\n", with: "\n")
        
        // remove randomly placed commas
        cleanedText = cleanedText.replacingOccurrences(of: " , ", with: " ") // CONCERN: may overlook periods read as commas for missing values
        cleanedText = cleanedText.replacingOccurrences(of: ", ", with: ". ") // CONCERN: c
        
        // remove extra spaces
        cleanedText = cleanedText.replacingOccurrences(of: "    ", with: " ")
        cleanedText = cleanedText.replacingOccurrences(of: "   ", with: " ")
        cleanedText = cleanedText.replacingOccurrences(of: "  ", with: " ")
        // CONCERN: multiple spaces can be more clear indications of new columns, whereas single spaces might just be parts of phrases
        
        // remove spaces on or before new lines
        cleanedText = cleanedText.replacingOccurrences(of: " \n", with: "\n")
        cleanedText = cleanedText.replacingOccurrences(of: "\n ", with: "\n")
        
        // additional cleaning for ending spaces and enters
        /*
        print("cleaned text is ")
        dump(cleanedText)
        while (cleanedText.dropLast() == "n" || cleanedText.dropLast() == " ") {
            print("Entered clean text")
            // remove empty spaces at the end of the string
            if (cleanedText.last == " ") {
                print("space removed")
                cleanedText.remove(at: cleanedText.index(before: cleanedText.endIndex))
            }
            if (cleanedText.count > 1) {
                //let index = cleanedText.index(cleanedText.endIndex, offsetBy: -2)
                let substr = cleanedText.suffix(2)
                print(substr)
                if (substr == "\n") {
                    print("enter removed")
                    cleanedText.remove(at: cleanedText.index(before: cleanedText.endIndex))
                    cleanedText.remove(at: cleanedText.index(before: cleanedText.endIndex))
                }
            }
        }
        */
        
        // use @ as the delimiter since spaces might be part of words
        cleanedText = cleanedText.replacingOccurrences(of: " ", with: String(DELIMITER))

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
            // direct conversion of text to CSV as is
            print("Using basic conversion")
            csvString = textToCSVBasic(forRows: rows)
        
        case .guesstimate:
            // guesses column number by averaging delimiter occurrences in rows to calculate value
            print("Using col guessing conversion")
            let columnNum = guessColumnNumber(forRows: rows, withDelimiter: DELIMITER)
            csvString = textToCSVGuesstimate(forRows: rows, withColumnNumber: columnNum)
        
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
            csvString += row.replacingOccurrences(of: " ", with: String(DELIMITER))
            csvString += "\n"
        }
        
        return csvString
    }
    
    private func textToCSVGuesstimate(forRows rows: [String], withColumnNumber columns: Int) -> String {
        var csvString = ""
        print("\n\n\nGuessing \(columns) columns")
        
        for row in rows {
            let rowColumns = getOccurrencesOf(of: DELIMITER, inString: row) + 1
            print("Row is: \(row) with \(rowColumns) columns")
            
            // add "" around numbers and words to escape for the use of commas
            var modedRow = addQuotesAroundRowItems(forRow: row)
            
            if rowColumns == columns {
                // columns in row are correct
                print("Row's columns are equal to average columns")

                csvString += modedRow.replacingOccurrences(of: String(DELIMITER), with: ",")
                csvString += "\n"
                
            } else if rowColumns > columns {
                // columns in row are too many
                print("Row's columns are more than average columns")
                
                // TODO: revise this implementation
                
                // basic implementation removes the shortest string column in the row
                modedRow = removeExtraColumnsFromRow(forRow: modedRow, withColumns: columns)
                csvString += modedRow.replacingOccurrences(of: String(DELIMITER), with: ",")
                csvString += "\n"
            } else {
                // columns in row are too few
                print("Row's columns are less than average columns")
                
                // attempt to add extra columns to row by splitting spaces in words
                modedRow = addExtraColumnsToRow(forRow: modedRow, withColumns: columns)
                
                csvString += modedRow.replacingOccurrences(of: String(DELIMITER), with: ",")
                csvString += "\n"
            }
        }
        
        return csvString
    }
    
    private func addQuotesAroundRowItems(forRow row: String) -> String {
        // split row into individual elements
        var items = row.split(separator: DELIMITER)
        
        var rowStr = ""
        
        for item in items {
            rowStr += "\"\(item)\"" + String(DELIMITER)
        }
        
        if (row != "") {
            rowStr.removeLast()
        }
        
        rowStr += "\n"
        print("The new row is \(rowStr)")
        return rowStr
    }
    
    private func removeExtraColumnsFromRow(forRow row: String, withColumns columns: Int) -> String {
        var strArray = row.split(separator: DELIMITER)
        print("Removing extra columns in: \(strArray)")
        
        // double check to see that row actually has too many columns
        if strArray.count > columns {
            while strArray.count > columns {
                if let min = strArray.min(by: {$1.count > $0.count}) {
                    print(min)
                    strArray.remove(at: strArray.index(of: min)!)
                }
            }
            
            var rowString = ""
            
            for i in 0...(strArray.count - 1) {
                rowString += strArray[i]
                if i != strArray.count - 1 {
                    rowString += String(DELIMITER)
                }
            }

            print(rowString)
            return rowString
        } else {
            return ""
        }
    }
    
    private func addExtraColumnsToRow(forRow row: String, withColumns columns: Int) -> String {
        if (row.contains(" ")) {
            print("split apart the items in row to add extra column")
            
            // attempt to replace a string with a delimiter and quotes
            var replacedRow = row
            if let replaceIndex = replacedRow.range(of: " ") {
                replacedRow.replaceSubrange(replaceIndex, with: "\"\(DELIMITER)\"")
            }
            return replacedRow
        } else {
            // return normal row if no empty spaces to split
            return row
        }
    }
    
    /*
     * method to guess the number of columns by averaging and rounding blank spaces for all rows
     */
    private func guessColumnNumber(forRows rows: [String], withDelimiter delimiter: Character) -> Int {
        var sum: Int = 0
        var rowCount: Int = 0
        for row in rows {
            sum += getOccurrencesOf(of: delimiter, inString: row)
            
            // only count rows with content to remove excess new lines at the end
            if (row.count > 0) {
                rowCount += 1
            }
        }
        print("Sum is \(sum) for \(rows.count) rows")
        var avg: Double = Double(sum) / Double(rowCount)
        
        // round down preferred for basic conversion because of tendancy of Tesseract to see extra characters but round nearest prefered for advanced which is more accurate
        // avg.round(.down)
        avg.round(.toNearestOrEven)
        
        // return average delmitters plus 1 to indicate number of columns
        return Int(avg) + 1
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
        print("Count of \(char) for \(str) is \(count)")
        return count
    }
}
