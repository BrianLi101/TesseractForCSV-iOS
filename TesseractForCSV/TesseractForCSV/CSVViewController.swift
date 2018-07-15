//
//  CSVViewController.swift
//  TesseractForCSV
//
//  Created by Brian Li on 7/15/18.
//  Copyright © 2018 Brian Li. All rights reserved.
//

import UIKit
import WebKit

class CSVViewController: UIViewController {

    private enum ScreenState {
        case `init`, normal, loading
    }
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var leftNavButton: UIBarButtonItem!
    @IBOutlet var rightNavButton: UIBarButtonItem!
    @IBOutlet var webView: WKWebView!
    
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    let ocrManager = OCRManager.sharedInstance
    
    var fileURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set web kit navigation delegate to get file loading updates
        webView.navigationDelegate = self
        
        // set up UI
        configureUIForState(.init)
        configureUIForState(.loading)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // load the file into the web view
        let url = self.fileURL
        self.webView.loadFileURL(url!, allowingReadAccessTo: url!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    private func configureUIForState(_ state: ScreenState) {
        switch (state) {
        case .init:

            // set navigation bar to clear
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationBar.shadowImage = UIImage()
            navigationBar.isTranslucent = true
            navigationBar.backgroundColor = .clear
            
            // setup activitity indicator
            activityIndicator.center = self.view.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.color = .black
            self.view.addSubview(activityIndicator)
            
        case .normal:

            activityIndicator.stopAnimating()
            rightNavButton.isEnabled = true
            
        case .loading:
            
            activityIndicator.startAnimating()
            rightNavButton.isEnabled = false
            
        default:
            print("Invalid ScreenState")
        }
    }
    
    /*
     * performs call to parent view controller to use word by word tesseract for better results
     */
    @IBAction func rightNavButtonPressed(_ sender: Any) {
        let imageConfirmationViewController = self.presentingViewController as! ImageConfirmationViewController
        
        // put UI in a loading state until processing finishes
        configureUIForState(.loading)
        
        // run advanced word by word Tesseract processing
        ocrManager.runAdvancedTesseractOCR(onImage: imageConfirmationViewController.imageView.image!, forObservations: imageConfirmationViewController.textBoxes) { (success, responseURL) in
            
            // update web view with new file if successful
            if (success) {
                self.updateFileURL(withFileURL: responseURL)
            }
        }
    }
    
    /*
     * exit window
     */
    @IBAction func leftNavButtonPressed(_ sender: Any) {
        // close to camera view
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    /*
     * method called from parent view controller to update to a new file
     */
    func updateFileURL(withFileURL fileURL: URL) {
        // start loading screen
        configureUIForState(.loading)
        
        // update the file url
        self.fileURL = fileURL
        
        // update the web view
        let url = self.fileURL
        self.webView.loadFileURL(url!, allowingReadAccessTo: url!)
    }
}

// MARK: -WKNavigationDelegate
extension CSVViewController: WKNavigationDelegate {
    /*
     * function called when navigation is completed
     */
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        // update UI to normal state when navigation is completed
        configureUIForState(.normal)
        
    }
}
