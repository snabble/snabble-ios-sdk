//
//  ScanningView.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit
import AVFoundation

/// custom barcode detectors need to conform to this protocol
public protocol BarcodeDetector {
    /// the scan formats that should be detected
    var scanFormats: [ScanFormat] { get set }

    /// the AVCaptureOutput to use
    var captureOutput: AVCaptureOutput { get }

    /// the ScanningViewDelegate
    var delegate: ScanningViewDelegate? { get set }

    /// the UIView for camera preview. Use this for scale calculations
    var cameraView: UIView? { get set }

    /// the UIView used to mark the detected code within the camera preview. Modify its frame
    /// when a barcode is detected
    var indicatorView: UIView? { get set }

    /// set this to true if the detector takes full control of the camera (e.g. CortexDecoder)
    /// in this case, you need to also implement all of the methods below
    var handlesCamera: Bool { get }

    func scannerWillAppear()

    func startScanning()

    func stopScanning()

    /// ask the detector for its camera preview
    func getCameraPreview(_ frame: CGRect) -> UIView?

    func setTorch(_ on: Bool)
}

public extension BarcodeDetector {
    var handlesCamera: Bool { return false }
    func scannerWillAppear() {}
    func startScanning() {}
    func stopScanning() {}
    func getCameraPreview(_ frame: CGRect) -> UIView? { return nil }
    func setTorch(_ on: Bool) {}
}

public protocol ScanningViewDelegate: class {

    /// called when the ScanningView needs to close itself
    #warning("do we still need this?")
    func closeScanningView()

    /// callback for a successful scan
    func scannedCode(_ code: String, _ format: ScanFormat)

    /// called to request camera permission
    #warning("how to handle this with the new detectors?")
    func requestCameraPermission(currentStatus: AVAuthorizationStatus)

    /// called when the "enter barcode" button is tapped
    func enterBarcode()

    /// called when the device has no back camera
    #warning("remove this")
    func noCameraFound()

    /// called when the shopping cart should be displayed
    func gotoShoppingCart()

    func track(_ event: AnalyticsEvent)
}

/// configuration of a ScanningView
public struct ScanningViewConfig {
    /// icon for the "enter barcode" button
    public var enterButtonImage: UIImage?

    /// icon for the inactive "torch toggle" button
    public var torchButtonImage: UIImage?

    /// icon for the active "torch toggle" button (if nil, `torchButtonImage` is used)
    public var torchButtonActiveImage: UIImage?

    /// text color for the cart button
    public var textColor = UIColor.white
    /// background color for the cart button
    public var backgroundColor = UIColor.clear

    /// border color for the "enter barcode" and "torch" buttons
    public var borderColor = UIColor.white

    /// color of the reticle's border. Default: 100% white, 20% alpha
    public var reticleBorderColor = UIColor(white: 1.0, alpha: 0.2)
    /// width of the reticle's border, default 0.5
    public var reticleBorderWidth: CGFloat = 0.5
    /// corner radius of the reticle's border, default 0
    public var reticleCornerRadius: CGFloat = 0

    /// height of the reticle, in pixels
    public var reticleHeight: CGFloat = 160

    /// color for the dimming overlay. Default: 13% white, 60% alpha
    public var dimmingColor = UIColor(white: 0.13, alpha: 0.6)

    /// initial visibility of the button bar
    public var bottomBarHidden = false

    /// which object types should be recognized. Default: EAN-13/UPC-A
    public var scanFormats = [ ScanFormat.ean13 ]

    /// delegate object, the ScanningView keeps a weak reference to this
    public var delegate: ScanningViewDelegate?

    /// if nil, use AVFoundation's built-in barcode detection, can be set to a host app's implementation eg. using Firebase/MLKit
    public var barcodeDetector: BarcodeDetector?

    public init() {}
}

@available(*, deprecated, message: "use BarcodeDetectorTNG instead")
public final class ScanningView: DesignableView {

    @IBOutlet weak var reticleWrapper: UIView!
    @IBOutlet weak var reticle: UIView!
    @IBOutlet weak var bottomBar: UIView!

    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var torchButton: UIButton!
    @IBOutlet weak var cartButton: UIButton!

    @IBOutlet weak var reticleHeight: NSLayoutConstraint!

    @objc private var camera: AVCaptureDevice? = AVCaptureDevice.default(for: AVMediaType.video)

    weak var delegate: ScanningViewDelegate!
    var scanFormats = [ScanFormat]()

    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer!

    var serialQueue = DispatchQueue(label: "io.snabble.scannerQueue")
    var metadataOutput: AVCaptureMetadataOutput?
    var barcodeDetector: BarcodeDetector?

    var dimmingColor: UIColor!
    var reticleBorderLayer: CAShapeLayer!   // dims the preview, leaving a hole for the reticle
    var firstLayoutDone = false
    var fullDimmingLayer: CAShapeLayer!     // dims the whole preview layer

    var frameView = UIView()    // indicator for where the barcode was detected
    var frameTimer: Timer?

    var torchImages = [ AVCaptureDevice.TorchMode: UIImage? ]()

    /// toggle the visibility of the "barcode entry" and "torch" buttons at the bottom
    public var bottomBarHidden = false {
        didSet {
            self.bottomBar.isHidden = bottomBarHidden
        }
    }

    public var cartButtonTitle: String? {
        didSet {
            UIView.performWithoutAnimation {
                self.cartButton.setTitle(self.cartButtonTitle, for: .normal)
                self.cartButton.isHidden = self.cartButtonTitle == nil
                self.cartButton.layoutIfNeeded()
            }
        }
    }

    public var reticleHidden = false {
        didSet {
            self.reticle.isHidden = reticleHidden
            self.reticleBorderLayer.isHidden = reticleHidden
            self.fullDimmingLayer.isHidden = !reticleHidden
        }
    }

    public override func awakeFromNib() {
        super.awakeFromNib()

        self.view.backgroundColor = .black
        self.reticle.backgroundColor = .clear
        self.reticle.layer.masksToBounds = true

        self.frameView.backgroundColor = .clear
        self.frameView.layer.borderColor = UIColor.lightGray.cgColor
        self.frameView.layer.borderWidth = 1
        self.frameView.layer.cornerRadius = 3
        self.view.addSubview(self.frameView)
        self.view.bringSubviewToFront(self.frameView)
    }

    /// this passes the `ScanningViewConfig` data to the ScanningView. This method must be called before the first pass of the
    /// layout engine, i.e. in you view controller's `viewDidLoad` or `viewWillAppear`
    public func setup(with config: ScanningViewConfig) {
        self.reticle.layer.borderColor = config.reticleBorderColor.cgColor
        self.reticle.layer.borderWidth = config.reticleBorderWidth
        self.reticle.layer.cornerRadius = config.reticleCornerRadius
        self.dimmingColor = config.dimmingColor

        self.searchButton.setImage(config.enterButtonImage, for: .normal)
        self.searchButton.layer.cornerRadius = 8
        self.searchButton.layer.backgroundColor = UIColor.clear.cgColor
        self.searchButton.layer.borderColor = config.borderColor.cgColor
        self.searchButton.layer.borderWidth = 1.0 / UIScreen.main.scale

        self.torchButton.setImage(config.torchButtonImage, for: .normal)
        self.torchButton.layer.cornerRadius = 8
        self.torchButton.layer.backgroundColor = UIColor.clear.cgColor
        self.torchButton.layer.borderColor = config.borderColor.cgColor
        self.torchButton.layer.borderWidth = 1.0 / UIScreen.main.scale

        self.cartButton.makeRoundedButton()
        self.cartButton.backgroundColor = config.backgroundColor
        self.cartButton.setTitleColor(config.textColor, for: .normal)
        self.cartButton.setTitle("Cart: XYZ €", for: .normal)

        self.barcodeDetector = config.barcodeDetector
        self.barcodeDetector?.cameraView = self.view
        self.barcodeDetector?.indicatorView = self.frameView
        
        self.delegate = config.delegate
        self.scanFormats = config.scanFormats

        self.bottomBarHidden = config.bottomBarHidden

        self.reticleHeight.constant = config.reticleHeight

        self.torchImages[.on] = config.torchButtonActiveImage ?? config.torchButtonImage
        self.torchImages[.off] = config.torchButtonImage

        if self.barcodeDetector == nil {
            self.metadataOutput = AVCaptureMetadataOutput()
        }

        self.barcodeDetector?.scannerWillAppear()
    }

    /// this must be called once to initialize the camera. If the app doesn't already have camera usage permission,
    /// the `requestCameraPermission` method of the delegate is called
    public func initializeCamera() {
        if self.checkCameraStatus() {
            self.initializeCaptureSession()
        }
    }

    /// start scanning
    public func startScanning() {
        self.frameView.isHidden = true
        self.frameView.frame = self.reticle.frame

        self.view.bringSubviewToFront(self.reticle)
        self.view.bringSubviewToFront(self.bottomBar)

        if let camera = self.camera {
            let torchToggleSupported = camera.isTorchModeSupported(.on) && camera.isTorchModeSupported(.off)
            self.torchButton.isHidden = !torchToggleSupported
        }

        self.initializeCaptureSession()
        self.startCaptureSession()
        self.setTorchButtonIcon()
        self.barcodeDetector?.startScanning()
    }

    private func startCaptureSession() {
        if self.barcodeDetector?.handlesCamera == true {
            return
        }

        if let capture = self.captureSession, !capture.isRunning, self.firstLayoutDone {
            self.serialQueue.async {
                capture.startRunning()
            }
        }
    }

    /// stop scanning
    public func stopScanning() {
        self.frameTimer?.invalidate()
        if let capture = self.captureSession, capture.isRunning {
            capture.stopRunning()
        }
        self.barcodeDetector?.stopScanning()
    }

    /// is it possible to scan?
    @available(*, deprecated, message: "no longer supported, this property will be removed soon")
    public func readyToScan() -> Bool {
        return self.captureSession != nil
    }

    public func setScanFormats(_ formats: [ScanFormat]) {
        self.barcodeDetector?.scanFormats = formats
        self.metadataOutput?.metadataObjectTypes = formats.map { $0.avType }
    }

    @IBAction func enterButtonTapped(_ button: UIButton) {
        self.delegate.enterBarcode()
    }
    
    @IBAction func torchButtonTapped(_ button: UIButton) {
        guard let camera = self.camera else {
            return
        }

        if self.barcodeDetector?.handlesCamera == true {
            let torchOn = camera.torchMode == .on
            self.barcodeDetector?.setTorch(!torchOn)
            self.setTorchButtonIcon()
            return
        }

        do {
            try camera.lockForConfiguration()
            defer { camera.unlockForConfiguration() }
            camera.torchMode = camera.torchMode == .on ? .off : .on
            self.setTorchButtonIcon()
            self.delegate.track(.toggleTorch)
        } catch {}
    }

    private func setTorchButtonIcon() {
        guard let camera = self.camera else {
            return
        }
        self.torchButton.setImage(self.torchImages[camera.torchMode] ?? nil, for: .normal)
        self.torchButton.backgroundColor = camera.torchMode == .on ? .white : .clear
    }

    @IBAction func cartButtonTapped(_ button: UIButton) {
        self.delegate.gotoShoppingCart()
    }

    private func checkCameraStatus() -> Bool {
        // get the back camera device
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else {
            self.delegate?.noCameraFound()
            return false
        }

        // camera found, are we allowed to access it?
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if authorizationStatus != .authorized {
            self.delegate.requestCameraPermission(currentStatus: authorizationStatus)
            return false
        }

        // set focus/low light properties of the back camera
        if camera.position == .back {
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
        }
        return true
    }

    // this is a terrible hack.
    // we need one pass through the layout system in order to figure out the position of the reticle, then force a second pass
    // and only then can we add the dimming overlay with the transparent "hole" at the right position
    public override func layoutSubviews() {
        super.layoutSubviews()

        guard self.dimmingColor != nil else {
            Log.error("setup() must be called before the first layout pass")
            return
        }

        if let previewLayer = self.previewLayer {
            previewLayer.frame = self.view.frame
        }

        if self.reticleBorderLayer == nil && self.firstLayoutDone {
            let overlayPath = UIBezierPath(rect: self.view.bounds)
            let rect = self.reticle.convert(self.reticle.bounds, to: self.view)
            let transparentPath = UIBezierPath(roundedRect: rect, cornerRadius: self.reticle.layer.cornerRadius)
            overlayPath.append(transparentPath)

            self.reticleBorderLayer = CAShapeLayer()
            self.reticleBorderLayer.path = overlayPath.cgPath
            self.reticleBorderLayer.fillRule = CAShapeLayerFillRule.evenOdd
            self.reticleBorderLayer.fillColor = self.dimmingColor.cgColor
            self.reticleBorderLayer.zPosition = -0.5
            self.view.layer.addSublayer(self.reticleBorderLayer)

            self.fullDimmingLayer = CAShapeLayer()
            let path = UIBezierPath(rect: self.view.bounds)
            self.fullDimmingLayer.path = path.cgPath
            self.fullDimmingLayer.fillColor = self.dimmingColor.cgColor
            self.fullDimmingLayer.zPosition = -0.5
            self.fullDimmingLayer.isHidden = true
            self.view.layer.addSublayer(self.fullDimmingLayer)
        }

        if !self.firstLayoutDone {
            self.setNeedsLayout()
        } else {
            let rect = self.reticle.frame
            if let metadataOutput = self.metadataOutput {
                if let layer = self.previewLayer, metadataOutput.rectOfInterest.origin.x == 0 {
                    let visibleRect = layer.metadataOutputRectConverted(fromLayerRect: rect)
                    metadataOutput.rectOfInterest = visibleRect
                }
            }

            if self.barcodeDetector?.handlesCamera == true {
                if let preview = self.barcodeDetector?.getCameraPreview(self.view.frame) {
                    self.view.addSubview(preview)
                }
            }
        }

        self.firstLayoutDone = true
    }

    private func initializeCaptureSession() {
        if self.barcodeDetector?.handlesCamera == true {
            return
        }

        guard self.captureSession == nil else {
            return
        }

        guard
            let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video),
            let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice)
        else {
            return
        }

        let captureSession = AVCaptureSession()

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        let captureOutput: AVCaptureOutput
        if let detector = self.barcodeDetector {
            captureOutput = detector.captureOutput
            captureSession.addOutput(captureOutput)
        } else if let metadataOutput = self.metadataOutput {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = self.scanFormats.map { $0.avType }
        } else {
            Log.error("scanner: initializeCaptureSession has no capture output")
        }

        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer.frame = self.view.frame
        self.previewLayer.videoGravity = .resizeAspectFill

        let rectOfInterest = self.previewLayer.metadataOutputRectConverted(fromLayerRect: self.reticle.frame)
        self.metadataOutput?.rectOfInterest = rectOfInterest

        self.previewLayer.zPosition = -1
        self.view.layer.addSublayer(self.previewLayer)

        self.captureSession = captureSession
    }
}

extension ScanningView: AVCaptureMetadataOutputObjectsDelegate {

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard
            let metadataObject = metadataObjects.first,
            let codeObject = metadataObject as? AVMetadataMachineReadableCodeObject,
            let code = codeObject.stringValue,
            let format = codeObject.type.scanFormat
        else {
            return
        }

        if let barCodeObject = self.previewLayer?.transformedMetadataObject(for: codeObject) {
            var bounds = barCodeObject.bounds
            let minSize: CGFloat = 60
            if bounds.height < minSize {
                bounds.size.height = minSize
                bounds.origin.y -= minSize / 2
            }
            if bounds.width < minSize {
                bounds.size.width = minSize
                bounds.origin.x -= minSize / 2
            }
            self.frameView.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.frameView.frame = bounds
            }

            self.frameTimer?.invalidate()
            self.frameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                self.frameView.isHidden = true
            }
        }

        self.delegate.scannedCode(code, format)
    }

}
