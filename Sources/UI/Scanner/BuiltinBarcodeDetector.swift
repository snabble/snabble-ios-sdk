//
//  BuiltinBarcodeDetector.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import SnabbleCore

extension ScanFormat {
    var avType: AVMetadataObject.ObjectType {
        switch self {
        case .ean8: return .ean8
        case .unknown, .ean13: return .ean13
        case .code128: return .code128
        case .code39: return .code39
        case .itf14: return .itf14
        case .qr: return .qr
        case .dataMatrix: return .dataMatrix
        case .pdf417: return .pdf417
        }
    }
}

extension AVMetadataObject.ObjectType {
    var scanFormat: ScanFormat? {
        switch self {
        case .ean13: return .ean13
        case .ean8: return .ean8
        case .code128: return .code128
        case .code39: return .code39
        case .itf14: return .itf14
        case .qr: return .qr
        case .dataMatrix: return .dataMatrix
        case .pdf417: return .pdf417
        default: return nil
        }
    }
}

public final class BuiltinBarcodeDetector: BarcodeCameraDetector {
    private var metadataOutput: AVCaptureMetadataOutput

    override public init(detectorArea: BarcodeDetectorArea) {
        self.metadataOutput = AVCaptureMetadataOutput()
        
        super.init(detectorArea: detectorArea)
        
        self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    }

    override public func scannerWillAppear(on view: UIView) {
        super.scannerWillAppear(on: view)
       
        self.captureSession.addOutput(self.metadataOutput)
        self.metadataOutput.metadataObjectTypes = self.scanFormats.map { $0.avType }
    }

    override public func setOverlayOffset(_ offset: CGFloat) {
        guard let overlay = self.decorationOverlay else {
            return
        }

        overlay.centerYOffset = offset
        DispatchQueue.main.async { [self] in
            overlay.layoutIfNeeded()
            let rect = previewLayer?.metadataOutputRectConverted(fromLayerRect: overlay.roi)
            sessionQueue.async { [self] in
                // for some reason, running this on the main thread may block for ~10 seconds. WHY?!?
                metadataOutput.rectOfInterest = rect ?? CGRect(origin: .zero, size: .init(width: 1, height: 1))
            }
        }
    }
}

extension BuiltinBarcodeDetector: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard
            let metadataObject = metadataObjects.first,
            let codeObject = metadataObject as? AVMetadataMachineReadableCodeObject,
            let code = codeObject.stringValue,
            let format = codeObject.type.scanFormat
        else {
            return
        }

        if let barcodeObject = self.previewLayer?.transformedMetadataObject(for: codeObject) {
            var bounds = barcodeObject.bounds
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let minSize: CGFloat = 60
            if bounds.height < minSize {
                bounds.size.height = minSize
                bounds.origin.y = center.y - minSize / 2
            }
            if bounds.width < minSize {
                bounds.size.width = minSize
                bounds.origin.x = center.x - minSize / 2
            }

            self.decorationOverlay?.showFrameView(at: bounds)
        }

        NSLog("got code \(code) \(format)")
        self.startIdleTimer()
        self.delegate?.scannedCode(code, format)
    }
}
