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

    public var cartButtonTitle: String? {
        didSet { self.updateCartButtonTitle() }
    }

    public var reticleVisible = true {
        didSet { self.toggleReticleVisibility() }
    }

    public var rectangleOfInterest: CGRect = .zero
    public var continuousScanning = false

    private var camera: AVCaptureDevice?
    private var captureSession: AVCaptureSession
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var metadataOutput: AVCaptureMetadataOutput
    private var sessionQueue: DispatchQueue

    private var appearance: BarcodeDetectorAppearance?
    private var decorationView: BarcodeDetectorOverlay?
    private var frameTimer: Timer?

    public required init(_ appearance: BarcodeDetectorAppearance? = nil) {
        self.appearance = appearance
        self.sessionQueue = DispatchQueue(label: "io.snabble.scannerQueue")
        self.captureSession = AVCaptureSession()
        self.metadataOutput = AVCaptureMetadataOutput()
        self.scanFormats = []

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
            return
        }

        self.camera = camera
        self.captureSession.addInput(videoInput)
        self.captureSession.addOutput(self.metadataOutput)
        self.metadataOutput.metadataObjectTypes = self.scanFormats.map { $0.avType }

        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = .zero

        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer

        if let appearance = self.appearance {
            let decorationView = BarcodeDetectorOverlay(appearance: appearance)
            view.addSubview(decorationView)

            NSLayoutConstraint.activate([
                decorationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                decorationView.topAnchor.constraint(equalTo: view.topAnchor),
                decorationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                decorationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            self.decorationView = decorationView
        }
    }

    public func scannerDidLayoutSubviews(_ cameraPreview: UIView) {
        if let previewLayer = self.previewLayer {
            previewLayer.frame = cameraPreview.bounds
        }

        decorationView?.torchButton.addTarget(self, action: #selector(self.torchButtonTapped(_:)), for: .touchUpInside)
        if let camera = self.camera {
            let torchToggleSupported = camera.isTorchModeSupported(.on) && camera.isTorchModeSupported(.off)
            decorationView?.torchButton.isHidden = !torchToggleSupported
        }

        decorationView?.enterButton.addTarget(self, action: #selector(self.enterButtonTapped(_:)), for: .touchUpInside)
        decorationView?.cartButton.addTarget(self, action: #selector(self.cartButtonTapped(_:)), for: .touchUpInside)
        // add the preview layer's decoration
//        if let appearance = self.appearance {
//            let decoration = BarcodeDetectorDecoration.add(to: cameraPreview, appearance: appearance)
//
//            decoration.torchButton.addTarget(self, action: #selector(self.torchButtonTapped(_:)), for: .touchUpInside)
//
//            if let camera = self.camera {
//                let torchToggleSupported = camera.isTorchModeSupported(.on) && camera.isTorchModeSupported(.off)
//                decoration.torchButton.isHidden = !torchToggleSupported
//            }
//
//            decoration.enterButton.addTarget(self, action: #selector(self.enterButtonTapped(_:)), for: .touchUpInside)
//            decoration.cartButton.addTarget(self, action: #selector(self.cartButtonTapped(_:)), for: .touchUpInside)
//
//            self.decoration = decoration
//        }

        self.updateCartButtonTitle()
    }

    public func pauseScanning() {
        self.sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }

    public func resumeScanning() {
        self.sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.commitConfiguration()
                self.captureSession.startRunning()

                // set the ROI matching the reticle on first start
                guard let previewLayer = self.previewLayer else {
                    return
                }

                DispatchQueue.main.async {
                    let frame = self.decorationView?.reticle.frame ?? self.rectangleOfInterest
                    let rectangleOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: frame)
                    self.metadataOutput.rectOfInterest = rectangleOfInterest
                }
            }
        }
    }

    public func startScanning() {
        self.resumeScanning()
    }

    public func stopScanning() {
        self.pauseScanning()
    }

    public func requestCameraPermission() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authorizationStatus != .authorized {
            self.requestCameraPermission(currentStatus: authorizationStatus)
        }
    }

    public func setTorch(_ on: Bool) {
        try? camera?.lockForConfiguration()
        defer { camera?.unlockForConfiguration() }
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
            let title = "Snabble.Scanner.Camera.accessDenied".localized()
            let msg = "Snabble.Scanner.Camera.allowAccess".localized()
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Snabble.Cancel".localized(), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Snabble.Settings".localized(), style: .default) { _ in
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

    private func updateCartButtonTitle() {
        UIView.performWithoutAnimation {
            self.decorationView?.cartButton.setTitle(self.cartButtonTitle, for: .normal)
            self.decorationView?.cartButton.isHidden = self.cartButtonTitle == nil
            self.decorationView?.cartButton.layoutIfNeeded()
        }
    }

    @objc private func enterButtonTapped(_ sender: Any) {
        self.delegate?.enterBarcode()
    }

    @objc private func torchButtonTapped(_ sender: Any) {
        guard let camera = self.camera else {
            return
        }

        do {
            try camera.lockForConfiguration()
            defer { camera.unlockForConfiguration() }
            camera.torchMode = camera.torchMode == .on ? .off : .on
            let torchImage = self.torchImage(for: camera.torchMode)
            self.decorationView?.torchButton.setImage(torchImage, for: .normal)
            self.delegate?.track(.toggleTorch)
        } catch {}
    }

    private func torchImage(for torchMode: AVCaptureDevice.TorchMode) -> UIImage? {
        guard let appearance = appearance else {
            return nil
        }

        switch torchMode {
        case .on: return appearance.torchButtonActiveImage ?? appearance.torchButtonImage
        default: return appearance.torchButtonImage
        }
    }

    @objc private func cartButtonTapped(_ sender: Any) {
        self.delegate?.gotoShoppingCart()
    }

    private func toggleReticleVisibility() {
        self.decorationView?.reticle.isHidden = self.reticleVisible
        self.decorationView?.reticleDimmingLayer.isHidden = !self.reticleVisible
        self.decorationView?.fullDimmingLayer.isHidden = self.reticleVisible
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
            }
            if bounds.width < minSize {
                bounds.size.width = minSize
            }

            self.decorationView?.frameView.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.decorationView?.frameView.frame = bounds
                self.decorationView?.frameView.center = center
            }

            self.frameTimer?.invalidate()
            self.frameTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                self.decorationView?.frameView.isHidden = true
            }
        }

        self.delegate?.scannedCode(code, format)
    }

}

extension BuiltinBarcodeDetector: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.decorationView?.cartButton.setCustomAppearance(appearance)
    }
}
