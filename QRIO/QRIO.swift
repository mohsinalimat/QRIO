//
//  QRIO.swift
//  Spenn
//
//  Created by Chris on 30/06/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import UIKit
import AVFoundation

class QRIO: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    var imageScanCompletionBlock: ((string: String) -> ())?
    
    static func QRImageFromString(string: String, containingViewSize: CGSize? = nil, correctionLevel: String = "L") -> UIImage? {
        let stringData = string.dataUsingEncoding(NSISOLatin1StringEncoding)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(stringData, forKey: "inputMessage")
        filter?.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        
        guard let resultImage = filter?.outputImage else { return nil }
        
        var scaleX = resultImage.extent.size.width
        var scaleY = resultImage.extent.size.height
        if let size = containingViewSize {
            scaleX = size.width / resultImage.extent.size.width
            scaleY = size.height / resultImage.extent.size.height
        }
        
        let qrImage = resultImage.imageByApplyingTransform(CGAffineTransformMakeScale(scaleX, scaleY))
        return UIImage(CIImage: qrImage)
        
    }
    
    func scanForQRImage(previewIn previewContainer: UIView? = nil, rectOfInterest: CGRect? = nil, completion: ((string: String) -> ())) {
        session = AVCaptureSession()
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            session?.addInput(input)
        } catch let error {
            print("Error: \(error)")
            return
        }
        
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        session?.addOutput(output)
        output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        imageScanCompletionBlock = completion
        
        session?.startRunning()
        if let previewContainer = previewContainer {
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer!.frame = previewContainer.bounds
            previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
            previewContainer.layer.addSublayer(previewLayer!)
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        var QRCode: String?
        for metadata in metadataObjects as! [AVMetadataObject] {
            if metadata.type == AVMetadataObjectTypeQRCode {
                QRCode = (metadata as! AVMetadataMachineReadableCodeObject).stringValue
            }
        }
        if let code = QRCode {
            imageScanCompletionBlock?(string: code)           
        }
    }
    
    func finish() {
        imageScanCompletionBlock = nil
        session?.stopRunning()
        previewLayer?.removeFromSuperlayer()
    }
}
