//
//  BuiltinBarcodeDetector.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import AVFoundation

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
        default: return nil
        }
    }
}

public final class BuiltinBarcodeDetector: NSObject, BarcodeDetector {
    public weak var delegate: BarcodeDetectorDelegate?

    public var scanFormats: [ScanFormat]

    private var camera: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var captureSession: AVCaptureSession
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var metadataOutput: AVCaptureMetadataOutput
    private var sessionQueue: DispatchQueue

    public private(set) var decorationOverlay: BarcodeDetectorOverlay?
    private weak var idleTimer: Timer?
    private var screenTap: UITapGestureRecognizer?
    private weak var messageDelegate: BarcodeDetectorMessageDelegate?
    private var detectorArea: BarcodeDetectorArea
    private var torchOn = false

    public required init(detectorArea: BarcodeDetectorArea, messageDelegate: BarcodeDetectorMessageDelegate?) {
        self.sessionQueue = DispatchQueue(label: "io.snabble.scannerQueue", qos: .userInitiated)
        self.captureSession = AVCaptureSession()
        self.metadataOutput = AVCaptureMetadataOutput()
        self.scanFormats = []
        self.messageDelegate = messageDelegate
        self.detectorArea = detectorArea

        super.init()

        self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    }

    public func scannerWillAppear(on view: UIView) {
        guard
            self.camera == nil,
            let camera = self.initializeCamera(),
            let videoInput = try? AVCaptureDeviceInput(device: camera),
            self.captureSession.canAddInput(videoInput)
        else {
            addOverlay(to: view)
            return
        }

        self.camera = camera
        self.videoInput = videoInput
        self.captureSession.addInput(videoInput)
        self.captureSession.addOutput(self.metadataOutput)
        self.metadataOutput.metadataObjectTypes = self.scanFormats.map { $0.avType }

        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = .zero

        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer

        addOverlay(to: view)

        if #available(iOS 15, *) {
            self.setRecommendedZoomFactor()
        }
    }

    private func addOverlay(to view: UIView) {
        guard self.decorationOverlay == nil else {
            return
        }

        let decorationOverlay = BarcodeDetectorOverlay(detectorArea: detectorArea)
        view.addSubview(decorationOverlay)
        NSLayoutConstraint.activate([
            decorationOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            decorationOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            decorationOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            decorationOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        self.decorationOverlay = decorationOverlay
    }

    public func scannerDidLayoutSubviews() {
        decorationOverlay?.layoutIfNeeded()
        if let previewLayer = self.previewLayer, let decorationOverlay = self.decorationOverlay {
            previewLayer.frame = decorationOverlay.bounds
        }
    }

    public func scannerWillDisappear() {
        // nop for the built-in detector
    }

    public func pauseScanning() {
        self.sessionQueue.async {
            self.captureSession.stopRunning()
        }
        self.stopIdleTimer()
    }

    public func resumeScanning() {
        self.sessionQueue.async {
            self.captureSession.startRunning()
        }
        self.startIdleTimer()
    }

    public func setOverlayOffset(_ offset: CGFloat) {
        guard let overlay = self.decorationOverlay else {
            return
        }

        overlay.centerYOffset = offset
        let rect = self.previewLayer?.metadataOutputRectConverted(fromLayerRect: overlay.roi)
        sessionQueue.async {
            // for some reason, running this on the main thread may block for ~10 seconds. WHY?!?
            self.metadataOutput.rectOfInterest = rect ?? CGRect(origin: .zero, size: .init(width: 1, height: 1))
        }
    }

    public func requestCameraPermission() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authorizationStatus != .authorized {
            self.requestCameraPermission(currentStatus: authorizationStatus)
        }
    }

    public func toggleTorch() -> Bool {
        setTorch(!torchOn)
        return torchOn
    }

    public func setTorch(_ on: Bool) {
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

    private func requestCameraPermission(currentStatus: AVAuthorizationStatus) {
        switch currentStatus {
        case .restricted, .denied:
            let title = L10n.Snabble.Scanner.Camera.accessDenied
            let msg = L10n.Snabble.Scanner.Camera.allowAccess
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: L10n.Snabble.cancel, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: L10n.Snabble.settings, style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            })
            DispatchQueue.main.async {
                self.delegate?.present(alert, animated: true, completion: nil)
            }

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in }

        default:
            assertionFailure("unhandled av auth status \(currentStatus.rawValue)")
        }
    }

    @available(iOS 15, *)
    private func setRecommendedZoomFactor() {
        guard let videoInput = self.videoInput else {
            return
        }

        let zoomFactor = RecommendedZoom.factor(for: videoInput)
        do {
            try videoInput.device.lockForConfiguration()
            videoInput.device.videoZoomFactor = CGFloat(zoomFactor)
            videoInput.device.unlockForConfiguration()
        } catch {
            print("Could not lock for configuration: \(error)")
        }
    }
}

// MARK: - idle timer
extension BuiltinBarcodeDetector {
    private func startIdleTimer() {
        guard
            UserDefaults.standard.bool(forKey: "io.snabble.sdk.batterySaver"),
            self.messageDelegate != nil
        else {
            return
        }

        self.idleTimer?.invalidate()
        self.idleTimer = Timer.scheduledTimer(withTimeInterval: 90, repeats: false) { _ in
            self.idleTimerFired()
        }
    }

    private func stopIdleTimer() {
        self.idleTimer?.invalidate()
    }

    private func idleTimerFired() {
        self.pauseScanning()
        self.screenTap = UITapGestureRecognizer(target: self, action: #selector(screenTapped(_:)))
        self.decorationOverlay?.addGestureRecognizer(self.screenTap!)

        self.messageDelegate?.showMessage(L10n.Snabble.Scanner.batterySaverHint) {
            self.resumeScanning()
        }
    }

    @objc private func screenTapped(_ gesture: UIGestureRecognizer) {
        self.decorationOverlay?.removeGestureRecognizer(self.screenTap!)
        self.resumeScanning()

        self.messageDelegate?.dismiss()
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
