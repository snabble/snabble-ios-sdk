//
//  BarcodeBufferDetector.swift
//  
//
//  Created by Uwe Tilemann on 03.05.24.
//

import Foundation
import AVFoundation
import UIKit
import SnabbleCore

public protocol BarcodeBufferDetectorDelegate: AnyObject {
    /// callback for a CMSampleBuffer output
    func didOutput(_ sampleBuffer: CMSampleBuffer)
}

open class BarcodeBufferDetector: BarcodeCameraDetector {
    public weak var videoDelegate: BarcodeBufferDetectorDelegate?

    override public init(detectorArea: BarcodeDetectorArea) {
        super.init(detectorArea: detectorArea)
    }

    override public func scannerWillAppear(on view: UIView) {
        super.scannerWillAppear(on: view)
       
        let output = AVCaptureVideoDataOutput()
        if self.captureSession.canAddOutput(output) {
            self.captureSession.addOutput(output)
        }
        output.setSampleBufferDelegate(self, queue: self.sessionQueue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as [String: Any]
    }
}

extension BarcodeBufferDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        videoDelegate?.didOutput(sampleBuffer)
    }
}
