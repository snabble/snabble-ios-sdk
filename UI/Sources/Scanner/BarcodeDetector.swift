//
//  BarcodeDetector.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import SnabbleCore

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

// Base class for the barcode detectors (iOS builtin and CortexDecoder)

// NOTE that this class is not really a part of the public API of the Snabble SDK - it and its properties are only marked
// `public`/`open` to support implementing `CortexDecoderBarcodeDetector` in its separate module

open class BarcodeDetector: NSObject {
    public static var batterySaverTimeout: TimeInterval { 90 }
    public static var batterySaverKey: String { "io.snabble.sdk.batterySaver" }

    /// the scan formats that should be detected, must be set before `scannerWillAppear()` is called.
    open var scanFormats: [ScanFormat]

    /// the expected width of a "standard" barcode, must be set before `scannerWillAppear()` is called.
    public var expectedBarcodeWidth: Int?

    public weak var delegate: BarcodeDetectorDelegate?
    public weak var messageDelegate: BarcodeDetectorMessageDelegate?

    public let sessionQueue: DispatchQueue
    public var torchOn = false

    public weak var idleTimer: Timer?
    public var screenTap: UITapGestureRecognizer?
    public var detectorArea: BarcodeDetectorArea
    public var decorationOverlay: BarcodeDetectorOverlay?

    public init(detectorArea: BarcodeDetectorArea) {
        self.scanFormats = []
        self.detectorArea = detectorArea

        self.sessionQueue = DispatchQueue(label: "io.snabble.scannerQueue", qos: .userInitiated)

        super.init()
    }

    // MARK: - idle timer
    @objc public func startIdleTimer() {
        guard
            UserDefaults.standard.bool(forKey: Self.batterySaverKey),
            self.messageDelegate != nil
        else {
            return
        }

        self.idleTimer?.invalidate()
        self.idleTimer = Timer.scheduledTimer(withTimeInterval: Self.batterySaverTimeout, repeats: false) { _ in
            self.idleTimerFired()
        }
    }

    @objc public func stopIdleTimer() {
        self.idleTimer?.invalidate()
    }

    private func idleTimerFired() {
        self.pauseScanning()
        self.screenTap = UITapGestureRecognizer(target: self, action: #selector(screenTapped(_:)))
        self.decorationOverlay?.addGestureRecognizer(self.screenTap!)

        self.messageDelegate?.showMessage(Asset.localizedString(forKey: "Snabble.Scanner.batterySaverHint")) {
            self.resumeScanning()
        }
    }

    @objc private func screenTapped(_ gesture: UIGestureRecognizer) {
        self.decorationOverlay?.removeGestureRecognizer(self.screenTap!)
        self.resumeScanning()

        self.messageDelegate?.dismiss()
    }

    // MARK: - torch
    // toggle the torch on/off. Returns the state after toggling
    open func toggleTorch() -> Bool {
        setTorch(!torchOn)
        return torchOn
    }

    // MARK: - foreground/background notifications
    public func startForegroundBackgroundObserver() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.stopIdleTimer), name: UIApplication.didEnterBackgroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(self.startIdleTimer), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    public func stopForegroundBackgroundObserver() {
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        nc.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    // MARK: - camera permission
    public func requestCameraPermission() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authorizationStatus != .authorized {
            self.requestCameraPermission(currentStatus: authorizationStatus)
        }
    }

    public func requestCameraPermission(currentStatus: AVAuthorizationStatus) {
        switch currentStatus {
        case .restricted, .denied:
            let title = Asset.localizedString(forKey: "Snabble.Scanner.Camera.accessDenied")
            let msg = Asset.localizedString(forKey: "Snabble.Scanner.Camera.allowAccess")
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.cancel"), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.settings"), style: .default) { _ in
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

    // MARK: - mandatory overrides
    /// this must be called from `viewWillAppear()` of the hosting view controller
    /// use this method to initialize the detector as well as the camera
    /// and add the camera preview view or layer to the given view
    open func scannerWillAppear(on view: UIView) { fatalError("clients must override") }

    /// this must be called from `viewDidLayoutSubviews()` of the hosting view controller.
    /// at this point, the bounds of the area reserved for camera preview have been determined
    /// and a barcode detector instance can resize its preview layer/view to these bounds
    open func scannerDidLayoutSubviews() { fatalError("clients must override") }

    /// this must be called from `viewWillDisappear()` of the hosting view controller.
    /// the view is about to disappear, and the detector can remove its camera preview from the
    /// view hiarchy, if neccessary
    open func scannerWillDisappear() { fatalError("clients must override") }

    /// instructs the detector to (re)start capturing video frames and detect barcodes
    open func pauseScanning() { fatalError("clients must override") }

    /// instructs the detector to stop capturing video frames and detect barcodes
    open func resumeScanning() { fatalError("clients must override") }

    /// set the scanner overlay's offset relative to the Y-axis center
    open func setOverlayOffset(_ offset: CGFloat) { fatalError("clients must override") }

    /// turn the torch on/off
    open func setTorch(_ on: Bool) { fatalError("clients must override") }
}
