//
//  BarcodeDetector.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import UIKit

public protocol BarcodeDetectorDelegate: class {
    /// callback for a successful scan
    func scannedCode(_ code: String, _ format: ScanFormat)

    /// called when the "enter barcode" button is tapped
    func enterBarcode()

    /// called when the "goto cart" button is tapped
    func gotoShoppingCart()

    /// track an `AnalyticsEvent`
    func track(_ event: AnalyticsEvent)

    /// this is used to present permission alerts. If the delegate instance is a `UIViewController`, no more code is needed
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

public protocol BarcodeDetector {
    /// the `BarcodeDetectorDelegate`. Implementations should make this `weak`
    var delegate: BarcodeDetectorDelegate? { get set }

    /// the cart button's title
    var cartButtonTitle: String? { get set }

    /// the scan formats that should be detected, must be set before `scannerWillAppear()` is called.
    var scanFormats: [ScanFormat] { get set }

    /// controls the visibility of the reticle
    var reticleVisible: Bool { get set }

    /// this must be called from `viewWillAppear()` of the hosting view controller
    /// use this method to initialize the detector as well as the camera
    func scannerWillAppear()

    /// this must be called from `viewDidLayoutSubviews()` of the hosting view controller.
    /// at this point, the bounds of the area reserved for camera preview have been determined
    /// and a barcode detector instance can place its preview layer/view at these coordinates
    func scannerDidLayoutSubviews(_ cameraPreview: UIView)

    /// instructs the detector to start capturing video frames and detect barcodes
    func startScanning()

    /// instructs the detector to stop capturing video frames and detect barcodes
    func stopScanning()

    /// sets the cart button's appearance
    func setCustomAppearance(_ appearance: CustomAppearance)
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

    /// show the button bar?
    public var bottomBarHidden = false

    public init() {}
}
