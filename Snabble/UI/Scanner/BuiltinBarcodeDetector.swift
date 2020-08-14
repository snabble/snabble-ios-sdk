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
        case .ean13: return .ean13
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

    public var reticleVisible: Bool = true {
        didSet { self.toggleReticleVisibility() }
    }

    public var rectangleOfInterest: CGRect = .zero
    public var continuousScanning: Bool = false

    private var camera: AVCaptureDevice?
    private var captureSession: AVCaptureSession
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var metadataOutput: AVCaptureMetadataOutput
    private var sessionQueue: DispatchQueue

    private var appearance: BarcodeDetectorAppearance?
    private var decoration: BarcodeDetectorDecoration?
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

    public func scannerWillAppear() {
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

        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer?.videoGravity = .resizeAspectFill
        self.previewLayer?.frame = .zero
    }

    public func scannerDidLayoutSubviews(_ cameraPreview: UIView) {
        if let previewLayer = self.previewLayer {
            previewLayer.frame = cameraPreview.bounds
            cameraPreview.layer.addSublayer(previewLayer)
        }

        // add the preview layer's decoration
        if let appearance = self.appearance {
            let decoration = BarcodeDetectorDecoration.add(to: cameraPreview, appearance: appearance)

            decoration.torchButton.addTarget(self, action: #selector(self.torchButtonTapped(_:)), for: .touchUpInside)

            if let camera = self.camera {
                let torchToggleSupported = camera.isTorchModeSupported(.on) && camera.isTorchModeSupported(.off)
                decoration.torchButton.isHidden = !torchToggleSupported
            }

            decoration.enterButton.addTarget(self, action: #selector(self.enterButtonTapped(_:)), for: .touchUpInside)
            decoration.cartButton.addTarget(self, action: #selector(self.cartButtonTapped(_:)), for: .touchUpInside)

            self.decoration = decoration
        }
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
                    let frame = self.decoration?.reticle.frame ?? self.rectangleOfInterest
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
            self.decoration?.cartButton.setTitle(self.cartButtonTitle, for: .normal)
            self.decoration?.cartButton.isHidden = self.cartButtonTitle == nil
            self.decoration?.cartButton.layoutIfNeeded()
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
            self.decoration?.torchButton.setImage(torchImage, for: .normal)
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
        self.decoration?.reticle.isHidden = self.reticleVisible
        self.decoration?.reticleDimmingLayer.isHidden = !self.reticleVisible
        self.decoration?.fullDimmingLayer.isHidden = self.reticleVisible
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

            self.decoration?.frameView.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.decoration?.frameView.frame = bounds
                self.decoration?.frameView.center = center
            }

            self.frameTimer?.invalidate()
            self.frameTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                self.decoration?.frameView.isHidden = true
            }
        }

        self.delegate?.scannedCode(code, format)
    }

}

/// creates the standard overlay decoration for the product scanner
public struct BarcodeDetectorDecoration {
    /// the visible reticle
    public let reticle: UIView
    /// the container for the buttons
    public let bottomBar: UIView
    /// the "enter barcode manually" button
    public let enterButton: UIButton
    /// the "toggle the torch" button
    public let torchButton: UIButton
    /// the "go to shopping cart" button
    public let cartButton: UIButton
    /// the frame for showing where the barcode was scanned
    public let frameView: UIView

    public let reticleDimmingLayer: CAShapeLayer
    public let fullDimmingLayer: CAShapeLayer

    /// add the standard overlay decoration for the product scanner
    ///
    /// - Parameters:
    ///   - cameraPreview: the view to add the decoration to. Note that the decoration is added based on that view's frame/bounds,
    ///     and therefore this should only be called after the view has been laid out.
    ///   - appearance: the appearance to use
    /// - Returns: a `BarcodeDetectorDecoration` instance that contains all views and buttons that were created
    // swiftlint:disable:next function_body_length
    public static func add(to cameraPreview: UIView, appearance: BarcodeDetectorAppearance) -> BarcodeDetectorDecoration {
        // the reticle itself
        let reticle = UIView(frame: .zero)
        reticle.backgroundColor = .clear
        reticle.layer.borderColor = appearance.reticleBorderColor.cgColor
        reticle.layer.borderWidth = 1 / UIScreen.main.scale
        reticle.layer.cornerRadius = appearance.reticleCornerRadius

        let bottomOffset: CGFloat = appearance.bottomBarHidden ? 0 : 64
        let reticleFrame = CGRect(x: 16,
                                  y: (cameraPreview.frame.height - bottomOffset - appearance.reticleHeight) / 2,
                                  width: cameraPreview.frame.width - 32,
                                  height: appearance.reticleHeight)
        reticle.frame = reticleFrame
        cameraPreview.addSubview(reticle)

        // a dimming layer with a hole for the reticle
        let overlayPath = UIBezierPath(rect: cameraPreview.bounds)
        let transparentPath = UIBezierPath(roundedRect: reticleFrame, cornerRadius: appearance.reticleCornerRadius)
        overlayPath.append(transparentPath)

        let borderLayer = CAShapeLayer()
        borderLayer.path = overlayPath.cgPath
        borderLayer.fillRule = .evenOdd
        borderLayer.fillColor = appearance.dimmingColor.cgColor
        cameraPreview.layer.addSublayer(borderLayer)

        // add the bottom bar
        let bottomBarFrame = CGRect(x: 16,
                                    y: cameraPreview.frame.height - 64,
                                    width: cameraPreview.frame.width - 32,
                                    height: 48)
        let bottomBar = UIView(frame: bottomBarFrame)
        bottomBar.isHidden = appearance.bottomBarHidden
        cameraPreview.addSubview(bottomBar)

        // a dimming layer that covers the whole preview
        let fullDimmingLayer = CAShapeLayer()
        let path = UIBezierPath(rect: cameraPreview.bounds)
        fullDimmingLayer.path = path.cgPath
        fullDimmingLayer.fillColor = appearance.dimmingColor.cgColor
        // fullDimmingLayer.zPosition = -0.5
        fullDimmingLayer.isHidden = true
        cameraPreview.layer.addSublayer(fullDimmingLayer)

        // barcode entry button
        let enterButton = UIButton(type: .custom)
        enterButton.frame = CGRect(origin: .zero, size: CGSize(width: 48, height: 48))
        enterButton.setImage(appearance.enterButtonImage, for: .normal)
        enterButton.layer.cornerRadius = 8
        enterButton.layer.borderColor = appearance.borderColor.cgColor
        enterButton.layer.borderWidth = 1.0 / UIScreen.main.scale
        bottomBar.addSubview(enterButton)

        // torch button
        let torchButton = UIButton(type: .custom)
        torchButton.frame = CGRect(origin: CGPoint(x: 48 + 16, y: 0), size: CGSize(width: 48, height: 48))
        torchButton.setImage(appearance.torchButtonImage, for: .normal)
        torchButton.layer.cornerRadius = 8
        torchButton.layer.borderColor = appearance.borderColor.cgColor
        torchButton.layer.borderWidth = 1.0 / UIScreen.main.scale
        bottomBar.addSubview(torchButton)

        // cart button
        let cartButton = UIButton(type: .system)
        let cartWidth = cameraPreview.frame.width - 2 * 48 - 4 * 16
        cartButton.frame = CGRect(origin: CGPoint(x: 48 + 16 + 48 + 16, y: 0), size: CGSize(width: cartWidth, height: 48))
        cartButton.layer.cornerRadius = 8
        cartButton.backgroundColor = appearance.backgroundColor
        cartButton.setTitleColor(appearance.textColor, for: .normal)
        cartButton.setTitle("", for: .normal)
        cartButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        bottomBar.addSubview(cartButton)

        // frame view
        let frameView = UIView(frame: .zero)
        frameView.backgroundColor = .clear
        frameView.layer.borderColor = UIColor.lightGray.cgColor
        frameView.layer.borderWidth = 1 / UIScreen.main.scale
        frameView.layer.cornerRadius = 3
        cameraPreview.addSubview(frameView)

        return BarcodeDetectorDecoration(reticle: reticle,
                                         bottomBar: bottomBar,
                                         enterButton: enterButton,
                                         torchButton: torchButton,
                                         cartButton: cartButton,
                                         frameView: frameView,
                                         reticleDimmingLayer: borderLayer,
                                         fullDimmingLayer: fullDimmingLayer)
    }

    public func removeFromSuperview() {
        self.reticle.removeFromSuperview()
        self.bottomBar.removeFromSuperview()
        self.enterButton.removeFromSuperview()
        self.torchButton.removeFromSuperview()
        self.cartButton.removeFromSuperview()
        self.frameView.removeFromSuperview()
        self.reticleDimmingLayer.removeFromSuperlayer()
        self.fullDimmingLayer.removeFromSuperlayer()
    }
}

extension BuiltinBarcodeDetector: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.decoration?.cartButton.setCustomAppearance(appearance)
    }
}
