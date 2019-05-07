//
//  BarcodeDetector.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

public protocol BarcodeDetectorTNG {
    /// creates a barcodedetector instance with the given visual parameters
    init(_ appearance: BarcodeDetectorAppearance)

    /// this will be called from `viewWillAppear()` of the hosting view controller
    /// use this method to initialize the detector as well as the camera
    func scannerWillAppear()

    /// this will be called from `viewDidLayoutSubviews()` of the hosting view controller.
    /// at this point, the bounds of the area reserved for camera preview have been determined
    /// and a barcode detector instance can place its preview layer/view at these coordinates
    func scannerDidLayoutSubviews(_ cameraPreview: UIView)

    /// instructs the detector to start capturing video frames and detect barcodes
    func startScanning()

    /// instructs the detector to stop capturing video frames and detect barcodes
    func stopScanning()

    /// the cart button's title
    var cartButtonTitle: String? { get set }

    /// the `ScanningViewDelegate`
    var delegate: ScanningViewDelegate? { get set }

    /// the scan formats that should be detected, must be set before `scannerWillAppear()` is called.
    var scanFormats: [ScanFormat] { get set }
}

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

public struct BarcodeDetectorAppearance {
    /// icon for the "enter barcode" button
    public var enterButtonImage: UIImage?

    /// icon for the inactive "torch toggle" button
    public var torchButtonImage: UIImage?

    /// icon for the active "torch toggle" button (if nil, `torchButtonImage` is used)
    public var torchButtonActiveImage: UIImage?

    /// text color for the "cart" button
    public var textColor = UIColor.white
    /// background color for the "cart" button
    public var backgroundColor = UIColor.clear

    /// border color for the "enter barcode" and "torch" buttons
    public var borderColor = UIColor.white

    /// color of the reticle's border, default: 100% white, 20% alpha
    public var reticleBorderColor = UIColor(white: 1.0, alpha: 0.2)
    /// width of the reticle's border, default 0.5
    public var reticleBorderWidth: CGFloat = 0.5
    /// corner radius of the reticle's border, default 0
    public var reticleCornerRadius: CGFloat = 0

    /// height of the reticle, in pixels
    public var reticleHeight: CGFloat = 160

    /// color for the dimming overlay, default: 13% white, 60% alpha
    public var dimmingColor = UIColor(white: 0.13, alpha: 0.6)

    /// initial visibility of the button bar
    public var bottomBarHidden = false

    public init() {}
}


public class BuiltinBarcodeDetector: NSObject, BarcodeDetectorTNG {

    public var delegate: ScanningViewDelegate?

    public var scanFormats = [ScanFormat]()

    public var cartButtonTitle: String? {
        didSet { self.updateCartButtonTitle() }
    }

    private var captureSession: AVCaptureSession
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var metadataOutput: AVCaptureMetadataOutput
    private var sessionQueue: DispatchQueue
    private var appearance: BarcodeDetectorAppearance
    private var torchButton: UIButton?
    private var cartButton: UIButton?

    required public init(_ appearance: BarcodeDetectorAppearance) {
        self.appearance = appearance
        self.sessionQueue = DispatchQueue(label: "io.snabble.scannerQueue")
        self.captureSession = AVCaptureSession()
        self.metadataOutput = AVCaptureMetadataOutput()

        super.init()

        self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    }

    public func scannerWillAppear() {
        guard
            let camera = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: camera),
            self.captureSession.canAddInput(videoInput)
        else {
            return
        }

        self.captureSession.addInput(videoInput)
        self.captureSession.addOutput(self.metadataOutput)
        self.metadataOutput.metadataObjectTypes = self.scanFormats.map { $0.avType }

        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer?.videoGravity = .resizeAspectFill
        self.previewLayer?.frame = .zero
    }

    public func scannerDidLayoutSubviews(_ cameraPreview: UIView) {
        guard self.previewLayer?.frame.size.height == 0 else {
            return
        }

        self.previewLayer?.frame = cameraPreview.bounds
        if let layer = self.previewLayer {
            cameraPreview.layer.addSublayer(layer)
        }

        // add the preview layer's decoration


        #warning("pull this out")
        // add the reticle
        let reticle = UIView(frame: .zero)
        reticle.backgroundColor = .clear
        reticle.layer.borderColor = self.appearance.reticleBorderColor.cgColor
        reticle.layer.borderWidth = 1 / UIScreen.main.scale
        reticle.layer.cornerRadius = self.appearance.reticleCornerRadius

        let reticleFrame = CGRect(x: 16,
                                  y: (cameraPreview.frame.height - 64 - self.appearance.reticleHeight) / 2,
                                  width: cameraPreview.frame.width - 32,
                                  height: self.appearance.reticleHeight)
        reticle.frame = reticleFrame
        cameraPreview.addSubview(reticle)

        let overlayPath = UIBezierPath(rect: cameraPreview.bounds)
        let transparentPath = UIBezierPath(roundedRect: reticleFrame, cornerRadius: self.appearance.reticleCornerRadius)
        overlayPath.append(transparentPath)

        let borderLayer = CAShapeLayer()
        borderLayer.path = overlayPath.cgPath
        borderLayer.fillRule = .evenOdd
        borderLayer.fillColor = self.appearance.dimmingColor.cgColor
        cameraPreview.layer.addSublayer(borderLayer)

        // add the bottom bar
        let bottomBar = UIView(frame: .zero)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        cameraPreview.addSubview(bottomBar)

        cameraPreview.addConstraint(NSLayoutConstraint(item: bottomBar, attribute: .left, relatedBy: .equal, toItem: cameraPreview, attribute: .left, multiplier: 1.0, constant: 16))
        cameraPreview.addConstraint(NSLayoutConstraint(item: bottomBar, attribute: .right, relatedBy: .equal, toItem: cameraPreview, attribute: .right, multiplier: 1.0, constant: -16))
        cameraPreview.addConstraint(NSLayoutConstraint(item: bottomBar, attribute: .bottom, relatedBy: .equal, toItem: cameraPreview, attribute: .bottom, multiplier: 1.0, constant: -16))
        cameraPreview.addConstraint(NSLayoutConstraint(item: bottomBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 48))

        // barcode entry button
        let enterButton = UIButton(type: .custom)
        enterButton.frame = CGRect(origin: .zero, size: CGSize(width: 48, height: 48))
        enterButton.setImage(appearance.enterButtonImage, for: .normal)
        enterButton.layer.cornerRadius = 8
        enterButton.layer.borderColor = self.appearance.borderColor.cgColor
        enterButton.layer.borderWidth = 1.0 / UIScreen.main.scale
        enterButton.addTarget(self, action: #selector(self.enterButtonTapped(_:)), for: .touchUpInside)
        bottomBar.addSubview(enterButton)

        // torch button
        let torchButton = UIButton(type: .custom)
        torchButton.frame = CGRect(origin: CGPoint(x: 48+16, y: 0), size: CGSize(width: 48, height: 48))
        torchButton.setImage(appearance.torchButtonImage, for: .normal)
        torchButton.layer.cornerRadius = 8
        torchButton.layer.borderColor = self.appearance.borderColor.cgColor
        torchButton.layer.borderWidth = 1.0 / UIScreen.main.scale
        torchButton.addTarget(self, action: #selector(self.torchButtonTapped(_:)), for: .touchUpInside)
        self.torchButton = torchButton
        bottomBar.addSubview(torchButton)

        // cart button
        let cartButton = UIButton(type: .system)
        let cartWidth = cameraPreview.frame.width - 2*48 - 4*16
        cartButton.frame = CGRect(origin: CGPoint(x: 48+16+48+16, y: 0), size: CGSize(width: cartWidth, height: 48))
        cartButton.layer.cornerRadius = 8
        cartButton.backgroundColor = self.appearance.backgroundColor
        cartButton.setTitleColor(self.appearance.textColor, for: .normal)
        cartButton.setTitle("Cart: 47,11 €", for: .normal)
        cartButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        cartButton.addTarget(self, action: #selector(self.cartButtonTapped(_:)), for: .touchUpInside)
        self.cartButton = cartButton
        bottomBar.addSubview(cartButton)
    }

    public func startScanning() {
        self.sessionQueue.async {
            print("start")
            self.captureSession.startRunning()
        }
    }

    public func stopScanning() {
        self.sessionQueue.async {
            print("stop")
            self.captureSession.stopRunning()
        }
    }

    // MARK: - private implementation

    private func updateCartButtonTitle() {
        self.cartButton?.setTitle(self.cartButtonTitle, for: .normal)
        self.cartButton?.isHidden = self.cartButtonTitle == nil
    }

    @objc func enterButtonTapped(_ sender: Any) {
        self.delegate?.enterBarcode()
    }

    @objc func torchButtonTapped(_ sender: Any) {
        #warning("implement me")
        print("toggle torch")
    }

    @objc func cartButtonTapped(_ sender: Any) {
        self.delegate?.gotoShoppingCart()
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

        self.delegate?.scannedCode(code, format)
    }

}
