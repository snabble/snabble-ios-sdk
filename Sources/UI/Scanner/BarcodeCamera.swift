//
//  BarcodeCamera.swift
//
//
//  Created by Uwe Tilemann on 02.05.24.
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

public protocol BarcodeBufferDelegate: AnyObject {
    /// callback for a CMSampleBuffer output
    func sampleOutput(_ sampleBuffer: CMSampleBuffer, completion: @escaping (BarcodeResult?) -> Void)
}

open class BarcodeCamera: BarcodeDetector {
    private var camera: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    
    public var captureSession: AVCaptureSession
    public var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let metadataOutputQueue: DispatchQueue
    private let metadataOutput: AVCaptureMetadataOutput

    private let videoDataoutputQueue: DispatchQueue
    private let videoDataOutput: AVCaptureVideoDataOutput
    public weak var bufferDelegate: BarcodeBufferDelegate? {
        didSet {
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
        }
    }
    
    public var removeDuplicatedCodes = true
    private var lastScannedCode: String?
    
    override public init(detectorArea: BarcodeDetectorArea) {
        captureSession = AVCaptureSession()
        
        metadataOutput = AVCaptureMetadataOutput()
        metadataOutputQueue = DispatchQueue(label: "metadataOutputQueue", qos: .background)
        
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] as [String: Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataoutputQueue = DispatchQueue(label: "videoDataOutputQueue", qos: .background)

        super.init(detectorArea: detectorArea)
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataOutputQueue)
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataoutputQueue)
    }

    override open func scannerWillAppear(on view: UIView) {
        startForegroundBackgroundObserver()

        guard
            self.camera == nil,
            let camera = self.initializeCamera(),
            let videoInput = try? AVCaptureDeviceInput(device: camera),
            self.captureSession.canAddInput(videoInput)
        else {
            return
        }

        self.camera = camera
        self.input = videoInput
        self.captureSession.addInput(videoInput)

        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = .zero

        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer

        addOverlay(to: view)

        if #available(iOS 15, *) {
            self.setRecommendedZoomFactor()
        }
                
        if self.captureSession.canAddOutput(self.metadataOutput) {
            self.captureSession.addOutput(self.metadataOutput)
            
            self.metadataOutput.metadataObjectTypes = self.scanFormats.map { $0.avType }
        }
   }

    private func addOverlay(to view: UIView) {
        guard self.decorationOverlay == nil else {
            return
        }

        let decorationOverlay = BarcodeOverlay(detectorArea: detectorArea)
        view.addSubview(decorationOverlay)
        NSLayoutConstraint.activate([
            decorationOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            decorationOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            decorationOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            decorationOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        self.decorationOverlay = decorationOverlay
    }

    override open func setOverlayOffset(_ offset: CGFloat) {
        
        guard let overlay = self.decorationOverlay else {
            return
        }
        overlay.centerYOffset = offset
        overlay.layoutIfNeeded()

        DispatchQueue.main.async { [self] in
            let rect = previewLayer?.metadataOutputRectConverted(fromLayerRect: overlay.roi)
            sessionQueue.async { [self] in
                // for some reason, running this on the main thread may block for ~10 seconds. WHY?!?
                metadataOutput.rectOfInterest = rect ?? CGRect(origin: .zero, size: .init(width: 1, height: 1))
            }
        }
    }

    override open func scannerDidLayoutSubviews() {
        decorationOverlay?.layoutIfNeeded()
        if let previewLayer = self.previewLayer, let decorationOverlay = self.decorationOverlay {
            previewLayer.frame = decorationOverlay.bounds
        }
    }

    override open func scannerWillDisappear() {
        stopForegroundBackgroundObserver()
    }

    override open func pauseScanning() {
        self.sessionQueue.async {
            self.captureSession.stopRunning()
        }
        self.stopIdleTimer()
    }

    override open func resumeScanning() {
        self.sessionQueue.async {
            self.captureSession.startRunning()
        }
        self.startIdleTimer()
    }

    override open func setTorch(_ on: Bool) {
        try? camera?.lockForConfiguration()
        defer { camera?.unlockForConfiguration() }
        torchOn = on
        camera?.torchMode = on ? .on : .off
    }

    // MARK: - private implementation

    private func initializeCamera() -> AVCaptureDevice? {
        // get the back camera device
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("no camera found")
            return nil
        }

        // camera found, are we allowed to access it?
        self.requestCameraPermission()

        // set focus/low light properties of the camera
        do {
            try camera.lockForConfiguration()
            defer { camera.unlockForConfiguration() }

            if camera.isAutoFocusRangeRestrictionSupported {
                camera.autoFocusRangeRestriction = .near
            }
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            if camera.isLowLightBoostSupported {
                camera.automaticallyEnablesLowLightBoostWhenAvailable = true
            }
        } catch {}

        return camera
    }

    @available(iOS 15, *)
    private func setRecommendedZoomFactor() {
        guard let videoInput = self.input else {
            return
        }

        let zoomFactor = RecommendedZoom.factor(for: videoInput, codeWidth: expectedBarcodeWidth)
        do {
            try videoInput.device.lockForConfiguration()
            videoInput.device.videoZoomFactor = CGFloat(zoomFactor)
            videoInput.device.unlockForConfiguration()
        } catch {
            print("Could not lock for configuration: \(error)")
        }
    }
    
    private func handleBarCodeResult(_ result: BarcodeResult) {
        print("got barcode \(result)")
        startIdleTimer()
        if removeDuplicatedCodes, result.code == lastScannedCode {
            return
        }
        delegate?.scannedCode(result)
    }
}

extension BarcodeCamera: AVCaptureMetadataOutputObjectsDelegate {
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
        let result = BarcodeResult(code: code, format: format)
        print("got barcode \(result)")
        handleBarCodeResult(result)
    }
}

extension BarcodeCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
       bufferDelegate?.sampleOutput(sampleBuffer) { [weak self] result in
           if let result, let self {
               handleBarCodeResult(result)
           }
        }
    }
}
