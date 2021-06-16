//
//  BarcodeDetector.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import UIKit

public protocol BarcodeDetectorDelegate: AnyObject {
    /// callback for a successful scan
    func scannedCode(_ code: String, _ format: ScanFormat)

    /// track an `AnalyticsEvent`
    func track(_ event: AnalyticsEvent)

    /// this is used to present permission alerts. If the delegate instance is a `UIViewController`, no more code is needed
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

public protocol BarcodeDetectorMessageDelegate: AnyObject {
    /// show a message covering the entire screen (used by the "battery saver" function e.g. in the Cortex Decoder implementation)
    /// `completion` is invoked when the user dimisses the message
    func showMessage(_ msg: String, completion: @escaping () -> Void)

    /// dismiss any message that might still be on-screen
    func dismiss()
}

public protocol BarcodeDetector {
    /// the `BarcodeDetectorDelegate`. Implementations should make this `weak`
    var delegate: BarcodeDetectorDelegate? { get set }

    /// the scan formats that should be detected, must be set before `scannerWillAppear()` is called.
    var scanFormats: [ScanFormat] { get set }

    var decorationOverlay: BarcodeDetectorOverlay? { get }

    /// this must be called from `viewWillAppear()` of the hosting view controller
    /// use this method to initialize the detector as well as the camera
    /// and add the camera preview view or layer to the given view
    func scannerWillAppear(on view: UIView)

    /// this must be called from `viewDidLayoutSubviews()` of the hosting view controller.
    /// at this point, the bounds of the area reserved for camera preview have been determined
    /// and a barcode detector instance can resize its preview layer/view to these bounds
    func scannerDidLayoutSubviews()

    /// this must be called from `viewWillDisappear()` of the hosting view controller.
    /// the view is about to disappear, and the detector can remove its camera preview from the
    /// view hiarchy, if neccessary
    func scannerWillDisappear()

    /// instructs the detector to (re)start capturing video frames and detect barcodes
    func pauseScanning()

    /// instructs the detector to stop capturing video frames and detect barcodes
    func resumeScanning()

    /// set the scanner overlay's offset relative to the Y-axis center
    func setOverlayOffset(_ offset: CGFloat)

    func requestCameraPermission()

    // toggle the torch on/off. Returns the state after toggling
    func toggleTorch() -> Bool

    // turn the torch
    func setTorch(_ on: Bool)
}
