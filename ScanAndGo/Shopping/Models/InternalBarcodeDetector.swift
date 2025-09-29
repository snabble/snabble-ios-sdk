//
//  InternalBarcodeDetector.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 14.06.24.
//

import Foundation
import OSLog
import SwiftUI
import Combine
import AVFoundation

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI
import CameraZoomWheel

public protocol BarcodeCameraDelegate: AnyObject {
    func requestCameraPermission(currentStatus: AVAuthorizationStatus)
}

extension InternalBarcodeDetector.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .idle:
            "idle"
        case .ready:
            "ready"
        case .scanning:
            "scanning"
        case .pausing:
            "pausing"
        case .batterySaving:
            "battery saving"
        }
        
    }
}

@Observable
open class InternalBarcodeDetector: NSObject, Zoomable, @unchecked Sendable {
    public static var batterySaverTimeout: TimeInterval { 90 }
    public static var batterySaverKey: String { "io.snabble.sdk.batterySaver" }
    public static var zoomValueKey: String { "io.snabble.sdk.zoomValue" }

    let logger = Logger(subsystem: "io.snabble.sdk.ScanAndGo", category: "InternalBarcodeDetector")
    
    /// the scan formats that should be detected, must be set before `scannerWillAppear()` is called.
    public var scanFormats: [ScanFormat] = []
    
    /// the expected width of a "standard" barcode, must be set before `scannerWillAppear()` is called.
    public var expectedBarcodeWidth: Int?
    
    public var zoomFactor: CGFloat? {
        didSet {
            guard let camera, let newValue = zoomFactor else {
                return
            }
            guard newValue >= camera.minAvailableVideoZoomFactor else { return }
            guard newValue <= camera.maxAvailableVideoZoomFactor else { return }

            do {
                try camera.lockForConfiguration()
                camera.ramp(toVideoZoomFactor: newValue, withRate: 4)
                camera.unlockForConfiguration()
                
                UserDefaults.standard.set(Float(newValue), forKey: Self.zoomValueKey)
            } catch {
                print("error ramping zoom: \(error)")
            }
        }
    }
    public var zoomSteps: [ZoomStep]? {
        guard let camera else {
            return nil
        }
        return camera.zoomSteps
    }
    
    public var torchOn = false
    public var message: String?

    public let barcodePublisher = PassthroughSubject<BarcodeResult, Never>()

    public enum State {
        case idle
        case ready
        case scanning
        case pausing
        case batterySaving
    }
    /// the current `state` of the detector
    public var state: State = .idle {
        didSet {
            logger.debug("detector changed from \(oldValue) -> \(self.state)")
            statePublisher.send(self.state)
        }
    }
    public let statePublisher = PassthroughSubject<InternalBarcodeDetector.State, Never>()

    public var previewLayer: AVCaptureVideoPreviewLayer?
    public var permissionGranted = false // Flag for permission
    
    public let sessionQueue: DispatchQueue
    
    public weak var batterySaverTimer: Timer?
    public var scanDebounce: TimeInterval = 3
    public var detectorArea: BarcodeDetectorArea
    
    private var camera: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    
    public var captureSession: AVCaptureSession
    
    private let metadataOutput: AVCaptureMetadataOutput
    
    private let outputQueue: DispatchQueue
    private let videoDataOutput: AVCaptureVideoDataOutput
    
    public weak var bufferDelegate: BarcodeBufferDelegate?
    public weak var cameraDelegate: BarcodeCameraDelegate?
    
    public init(detectorArea: BarcodeDetectorArea) {
        self.detectorArea = detectorArea
        
        self.sessionQueue = DispatchQueue(label: "io.snabble.scannerQueue", qos: .userInitiated)
        
        captureSession = AVCaptureSession()
        
        metadataOutput = AVCaptureMetadataOutput()
        
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] as [String: Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        outputQueue = DispatchQueue(label: "outputQueue", qos: .background)
        
        super.init()
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: outputQueue)
        videoDataOutput.setSampleBufferDelegate(self, queue: outputQueue)
    }
    
    public var hasCamera: Bool {
        self.camera != nil
    }
    
    open func setup() {
        
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
        
        // Built-in Decoding
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.metadataObjectTypes = scanFormats.map { $0.avType }
        }
        
        // Buffer Decoding
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = .zero
        
        self.previewLayer = previewLayer
        
        if #available(iOS 15, *) {
            self.setRecommendedZoomFactor()
        }
        self.state = .ready
    }
    
    open func start() {
        startForegroundBackgroundObserver()
        resumeScanning()
    }
    open func stop() {
        stopForegroundBackgroundObserver()
        pauseScanning()
    }
    
    // MARK: - foreground/background notifications
    public func startForegroundBackgroundObserver() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.stopBatterySaverTimer), name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.addObserver(self, selector: #selector(self.startBatterySaverTimer), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    public func stopForegroundBackgroundObserver() {
        let center = NotificationCenter.default
        center.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    // MARK: - idle timer
    @objc public func startBatterySaverTimer() {
        guard UserDefaults.standard.bool(forKey: Self.batterySaverKey) else {
            return
        }
        
        batterySaverTimer?.invalidate()
        batterySaverTimer = Timer.scheduledTimer(withTimeInterval: Self.batterySaverTimeout, repeats: false) { [weak self] _ in
            self?.batterySaverTimerFired()
        }
    }
    
    @objc public func stopBatterySaverTimer() {
        self.batterySaverTimer?.invalidate()
    }
    
    private func batterySaverTimerFired() {
        // self.pauseScanning()
        self.state = .batterySaving
    }
    
    /// instructs the detector to (re)start capturing video frames and detect barcodes
    open func pauseScanning() {
        self.sessionQueue.async {
            self.captureSession.stopRunning()
        }
        self.stopBatterySaverTimer()
        self.state = .pausing
    }
    
    /// instructs the detector to stop capturing video frames and detect barcodes
    open func resumeScanning() {
        self.sessionQueue.async {
            self.captureSession.startRunning()
        }
        self.startBatterySaverTimer()
        self.state = .scanning
    }
    
    open func setTorch(_ switchedOn: Bool) {
        try? camera?.lockForConfiguration()
        defer { camera?.unlockForConfiguration() }
        torchOn = switchedOn
        camera?.torchMode = switchedOn ? .on : .off
    }
    
    open func toggleTorch() -> Bool {
        setTorch(!torchOn)
        return torchOn
    }

    /// Sets the region of interrest
    open func setROI(rect roi: CGRect) {
        DispatchQueue.main.async { [self] in
            let rect = previewLayer?.metadataOutputRectConverted(fromLayerRect: roi)
            sessionQueue.async { [self] in
                // for some reason, running this on the main thread may block for ~10 seconds. WHY?!?
                metadataOutput.rectOfInterest = rect ?? CGRect(origin: .zero, size: .init(width: 1, height: 1))
            }
        }
    }
    
    // MARK: - private implementation
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Permission has been granted before
        case .authorized:
            permissionGranted = true
            
            // Permission has not been requested yet
        case .notDetermined:
            requestCameraPermission()
            
        default:
            permissionGranted = false
        }
    }
    private func requestCameraPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    private func initializeCamera() -> AVCaptureDevice? {
        // get the back camera device
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            logger.debug("no camera found")
            return nil
        }
        
        // camera found, are we allowed to access it?
        // self.requestCameraPermission()
        checkPermission()
        
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
            // swiftlint:disable:next no_empty_block
        } catch {}
        
        return camera
    }
    
    @available(iOS 15, *)
    private func setRecommendedZoomFactor() {
        guard let videoInput = self.input else {
            return
        }
        let zoomFactor: Float
        if UserDefaults.standard.object(forKey: Self.zoomValueKey) != nil {
            zoomFactor = UserDefaults.standard.float(forKey: Self.zoomValueKey)
        } else {
            zoomFactor = RecommendedZoom.factor(for: videoInput, codeWidth: expectedBarcodeWidth)
        }
        self.zoomFactor = CGFloat(zoomFactor)
    }
    
    private var lastScannedTime: Date?
    private func handleBarCodeResult(_ result: BarcodeResult) {
        startBatterySaverTimer()
        if let lastScannedTime, lastScannedTime.addingTimeInterval(scanDebounce) > .now {
            return
        }
        lastScannedTime = .now
        barcodePublisher.send(result)
        logger.debug("handleBarCodeResult \(result.description)")
    }
}

extension InternalBarcodeDetector: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard
            let metadataObject = metadataObjects.first,
            let codeObject = metadataObject as? AVMetadataMachineReadableCodeObject,
            let code = codeObject.stringValue,
            let format = codeObject.type.scanFormat
        else {
            return
        }
        
        let result = BarcodeResult(code: code, format: format)
        handleBarCodeResult(result)
    }
}

extension InternalBarcodeDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        bufferDelegate?.sampleOutput(sampleBuffer) { [weak self] result in
            if let result, let self {
                handleBarCodeResult(result)
            }
        }
    }
}
