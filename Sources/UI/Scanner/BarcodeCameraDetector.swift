//
//  BarcodeCameraDetector.swift
//
//
//  Created by Uwe Tilemann on 02.05.24.
//

import Foundation
import AVFoundation
import UIKit
import SnabbleCore

open class BarcodeCameraDetector: BarcodeDetector {
    private var camera: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    public var captureSession: AVCaptureSession
    public var previewLayer: AVCaptureVideoPreviewLayer?
    
    override public init(detectorArea: BarcodeDetectorArea) {
        self.captureSession = AVCaptureSession()
    
        super.init(detectorArea: detectorArea)
    }

    override public func scannerWillAppear(on view: UIView) {
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

    override public func scannerDidLayoutSubviews() {
        decorationOverlay?.layoutIfNeeded()
        if let previewLayer = self.previewLayer, let decorationOverlay = self.decorationOverlay {
            previewLayer.frame = decorationOverlay.bounds
        }
    }

    override public func scannerWillDisappear() {
        stopForegroundBackgroundObserver()
    }

    override public func pauseScanning() {
        self.sessionQueue.async {
            self.captureSession.stopRunning()
        }
        self.stopIdleTimer()
    }

    override public func resumeScanning() {
        self.sessionQueue.async {
            self.captureSession.startRunning()
        }
        self.startIdleTimer()
    }

    override public func setTorch(_ on: Bool) {
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
}
