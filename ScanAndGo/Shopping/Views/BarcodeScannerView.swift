//
//  BarcodeScannerView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 14.06.24.
//

import Foundation
import OSLog
import SwiftUI
import AVFoundation

import SnabbleAssetProviding

class BarcodeScannerViewController: UIViewController {
    let detector: InternalBarcodeDetector
    let logger = Logger(subsystem: "io.snabble.sdk.ScanAndGo", category: "BarcodeScannerViewController")
    
    init(detector: InternalBarcodeDetector) {
        self.detector = detector
        super.init(nibName: nil, bundle: nil)
    }
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadView() {
        self.view = UIView(frame: UIScreen.main.bounds)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        
        if let previewLayer = detector.previewLayer {
            addLayer(previewLayer, to: self)
        }
    }

    func addLayer(_ layer: CALayer, to viewController: UIViewController) {
        let bounds = viewController.view.bounds
        layer.frame = bounds
        logger.debug("preview layer size: \(bounds.width) x \(bounds.height)")

        if layer.superlayer == nil {
            Task { @MainActor in
                viewController.view.layer.addSublayer(layer)
            }
        }
    }
}

public struct BarcodeScannerView: UIViewControllerRepresentable {
//    @SwiftUI.Environment(\.safeAreaInsets) var insets
    
    public let detector: InternalBarcodeDetector
    
    public init(detector: InternalBarcodeDetector = .init(detectorArea: .rectangle)) {
        self.detector = detector
    }
    
    public func makeUIViewController(context: UIViewControllerRepresentableContext<BarcodeScannerView>) -> UIViewController {
        return BarcodeScannerViewController(detector: detector)
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<BarcodeScannerView>) {
        guard let vc = uiViewController as? BarcodeScannerViewController,
              let previewLayer = detector.previewLayer,
              previewLayer.superlayer == nil else { return }
        vc.addLayer(previewLayer, to: vc)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    public class Coordinator: NSObject {
        var parent: BarcodeScannerView
        nonisolated(unsafe) private var stateTask: Task<Void, Never>?

        init(_ parent: BarcodeScannerView) {
            self.parent = parent
            super.init()
            let detector = parent.detector

            // Defer setup() via Task to avoid mutating @Observable state during the SwiftUI
            // render pass, which would cause an AttributeGraph cycle and corrupt position state.
            stateTask = Task { @MainActor [detector] in
                if !detector.hasCamera {
                    detector.setup()
                }
                for await state in detector.statePublisher.values {
                    if case .idle = state {
                        detector.setup()
                    }
                }
            }
        }

        deinit {
            stateTask?.cancel()
        }
    }
}

// MARK: - Barcode Scanner View
public struct BarcodeScanner: UIViewRepresentable {
    public let detector: InternalBarcodeDetector
    
    public init(detector: InternalBarcodeDetector = .init(detectorArea: .rectangle)) {
        self.detector = detector
    }
    
    public func makeUIView(context: Context) -> ScannerContainerView {
        let containerView = ScannerContainerView()
        
        if let preview = detector.previewLayer {
            containerView.setupPreviewLayer(preview)
        }
        return containerView
    }
    
    public func updateUIView(_ uiView: ScannerContainerView, context: Context) {
        if let previewLayer = detector.previewLayer, previewLayer.superlayer == nil {
            uiView.setupPreviewLayer(previewLayer)
        }
        guard uiView.bounds.width > 0 && uiView.bounds.height > 0 else { return }
        uiView.updatePreviewLayerFrame()
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    public class Coordinator: NSObject {
        var parent: BarcodeScanner
        nonisolated(unsafe) private var stateTask: Task<Void, Never>?

        init(_ parent: BarcodeScanner) {
            self.parent = parent
            super.init()
            let detector = parent.detector

            stateTask = Task { @MainActor [detector] in
                if !detector.hasCamera {
                    detector.setup()
                }
                for await state in detector.statePublisher.values {
                    if case .idle = state {
                        detector.setup()
                    }
                }
            }
        }

        deinit {
            stateTask?.cancel()
        }
    }
}

// MARK: - Container View mit Layout-Management
public class ScannerContainerView: UIView {
    private var previewLayer: CALayer?
    private var hasSetInitialFrame = false
    
    func setupPreviewLayer(_ layer: CALayer) {
        self.previewLayer = layer
        self.layer.addSublayer(layer)
        
        // Initial frame setzen (wird später aktualisiert)
        layer.frame = self.bounds
    }
    
    func updatePreviewLayerFrame() {
        guard let previewLayer = previewLayer else { return }
        

        // Frame nur aktualisieren wenn sich die Größe geändert hat
        let newFrame = self.bounds
        if !previewLayer.frame.equalTo(newFrame) {
            
            // Animation für smooth Übergänge
            CATransaction.begin()
            CATransaction.setDisableActions(false)
            CATransaction.setAnimationDuration(0.2)
            
            previewLayer.frame = newFrame
            
            CATransaction.commit()
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        // Zusätzliche Sicherheit: Frame auch in layoutSubviews setzen
        updatePreviewLayerFrame()
    }
}

private struct BarcodeScannerInternal: UIViewRepresentable {
    let detector: InternalBarcodeDetector
    let size: CGSize
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        if let preview = detector.previewLayer {
            preview.frame = CGRect(origin: .zero, size: size)
            view.layer.addSublayer(preview)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            let newFrame = CGRect(origin: .zero, size: size)
            
            if !previewLayer.frame.equalTo(newFrame) {
                previewLayer.frame = newFrame
            }
        }
    }
}
