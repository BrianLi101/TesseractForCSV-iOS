# TesseractForCSV-iOS
An iOS application that converts an image of a table into a .csv file by using Tesseract OCR and additional formatting algorithms.

<img src="TesseractForCSV-iOS-DemoGif.gif" height="500">

# Getting Started
## Cloning File
Open a Terminal window to the folder in which you want to download your project and run:
```
git clone --recurse-submodules https://github.com/BrianLi101/TesseractForCSV-iOS.git
```
This will clone both the repo and the [GPUImage2](https://github.com/BradLarson/GPUImage2) submodule that is used for image processing.

Alternatively, you can download the project as a zip file and separately include [GPUImage2](https://github.com/BradLarson/GPUImage2) at a later step.

## Installing Pods
Open a Terminal window at the ```TesseractForCSV``` folder and run:
```
pod install
```
This will install the [Tesseract-OCR-iOS](https://github.com/gali8/Tesseract-OCR-iOS) framework that is used for optical character recognition.

Click on the ```Pods``` project in Xcode. Go to ```Targets->TesseractOCRiOS->Build Settings->EnableBitcode->No```.

If you haven't used CocoaPods before, you can install it by following the instructions at [CocoaPods.org](https://cocoapods.org/).

## Installing GPUImage2
If you have already installed the [GPUImage2](https://github.com/BradLarson/GPUImage2) submodule, follow the instructions for [Using GPUImage in an Mac or iOS Application](https://github.com/BradLarson/GPUImage2#using-gpuimage-in-an-mac-or-ios-application).

If you have not yet installed the [GPUImage2](https://github.com/BradLarson/GPUImage2) submodule, download it and drag it into the ```TesseractForCSV-iOS``` folder. Then follow the instructions for [Using GPUImage in an Mac or iOS Application](https://github.com/BradLarson/GPUImage2#using-gpuimage-in-an-mac-or-ios-application).

# Common Issues
```
No such module 'TesseractOCR'
```
Clean your build by going to ```Product->Clean``` or clicking ```Command+Shift+K```. If the problem continues to persist, go to ```File->Workspace Settings...``` and delete the derived data folder associated with the app.


```
ld: -weak_library and -bitcode_bundle (Xcode setting ENABLE_BITCODE=YES) cannot be used together
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```
Click on the Pods project in Xcode. Go to ```Targets->TesseractOCRiOS->Build Settings->EnableBitcode->No```.


```
No such module 'GPUImage'
```
Follow the instructions for [Using GPUImage in an Mac or iOS Application](https://github.com/BradLarson/GPUImage2#using-gpuimage-in-an-mac-or-ios-application).

## Known Limitations
* Unable to recognize handwriting or fonts that are not part of the trained data.
* Advanced OCR function fails to recognize individual characters.
* Poor or uneven lighting will result in blemishes on the image confirmation page, which signifcantly reduces OCR accuracy.

## Acknowledgements
* https://github.com/tesseract-ocr/tesseract
* https://github.com/gali8/Tesseract-OCR-iOS
* https://github.com/BradLarson/GPUImage2
* https://github.com/appcoda/TextDetection
* https://github.com/onmyway133/BigBigNumbers
