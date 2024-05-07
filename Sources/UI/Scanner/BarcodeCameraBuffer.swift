//
//  BarcodeCameraBuffer.swift
//  
//
//  Created by Uwe Tilemann on 03.05.24.
//

import Foundation
import AVFoundation
import UIKit
import SnabbleCore

public protocol BarcodeBufferDelegate: AnyObject {
    /// callback for a CMSampleBuffer output
    func sampleOutput(_ sampleBuffer: CMSampleBuffer, completion: @escaping (BarcodeResult?) -> Void)
}

open class BarcodeCameraBuffer: BarcodeCamera {
    public weak var bufferDelegate: BarcodeBufferDelegate?

    private let outputQueue = DispatchQueue(label: "outputQueue", qos: .background)
    private let output = AVCaptureVideoDataOutput()

    override open func scannerWillAppear(on view: UIView) {
        super.scannerWillAppear(on: view)
       
        if self.captureSession.canAddOutput(output) {
            self.captureSession.addOutput(output)
        }
        output.setSampleBufferDelegate(self, queue: outputQueue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] as [String: Any]
        output.alwaysDiscardsLateVideoFrames = true
    }
}

extension BarcodeCameraBuffer: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
       bufferDelegate?.sampleOutput(sampleBuffer) { result in
           if let result {
               self.delegate?.scannedCode(result)
           }
        }
    }
}
