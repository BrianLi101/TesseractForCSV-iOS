//
//  Extensions.swift
//  TesseractForCSV
//
//  Created by Brian Li on 7/15/18.
//  Copyright © 2018 Brian Li. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    /*
     * extension method that rotates image to reorient it rather than just store the imageOrientation as a property
     */
    func orientedImage() -> UIImage {
        UIGraphicsBeginImageContext(self.size)
        self.draw(at: .zero)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}
