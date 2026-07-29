//
//  BarcodeDetecting.swift
//  SnabbleScanAndGo
//

import AVFoundation
import CameraZoomWheel
import SnabbleCore

/// Protocol abstracting a barcode detector, enabling composition-based implementations
/// without requiring subclassing of `InternalBarcodeDetector`.
///
/// Both `InternalBarcodeDetector` and composition-based wrappers (e.g. for CortexDecoder)
/// conform to this protocol, allowing `BarcodeManager` and views to work with either
/// implementation via `any BarcodeDetecting`.
public protocol BarcodeDetecting: AnyObject {
    var state: InternalBarcodeDetector.State { get }
    var scanFormats: [ScanFormat] { get set }
    var barcodeStream: AsyncStream<BarcodeResult> { get }
    var stateStream: AsyncStream<InternalBarcodeDetector.State> { get }
    var previewLayer: AVCaptureVideoPreviewLayer? { get }
    var hasCamera: Bool { get }
    var zoomFactor: CGFloat? { get set }
    var zoomSteps: [ZoomStep]? { get }
    var bufferDelegate: BarcodeBufferDelegate? { get set }
    func setup()
    func start()
    func stop()
    func pauseScanning()
    func resumeScanning()
    func setROI(rect roi: CGRect)
    func setTorch(_ on: Bool)
    @discardableResult func toggleTorch() -> Bool
}

extension InternalBarcodeDetector: BarcodeDetecting {}
