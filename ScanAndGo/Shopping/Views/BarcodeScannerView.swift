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
import Combine

import SnabbleAssetProviding
import SnabbleUI

class BarcodeScannerViewController: UIViewController {
    let detector: InternalBarcodeDetector
    let logger = Logger(subsystem: "io.snabble.sdk.ScanAndGo", category: "BarcodeScannerViewController")
    
    private var subscriptions = Set<AnyCancellable>()
    
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
        self.view.backgroundColor = .systemGray
        
        if let previewLayer = detector.previewLayer {
            addLayer(previewLayer, to: self)
        } else {
            logger.warning("camera preview is not available")
#if targetEnvironment(simulator)
            let layer = CAGradientLayer()
            layer.colors = [UIColor.projectPrimary().cgColor, UIColor.white.cgColor]
            addLayer(layer, to: self)
#endif
        }
    }
    private func addLayer(_ layer: CALayer, to viewController: UIViewController) {
        let frame = viewController.view.bounds
        let insets = UIApplication.shared.sceneKeyWindow?.safeAreaInsets ?? UIEdgeInsets()
        
        let rect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - insets.top - insets.bottom - UITabBarController().height)
        
        layer.frame = rect
        logger.debug("preview layer size: \(rect.width) x \(rect.height)")
        
        if layer.superlayer == nil {
            DispatchQueue.main.async {
                viewController.view.layer.addSublayer(layer)
            }
        }
    }
}

public struct BarcodeScannerView: UIViewControllerRepresentable {
    @SwiftUI.Environment(\.safeAreaInsets) var insets
    
    public let detector: InternalBarcodeDetector
    
    public init(detector: InternalBarcodeDetector = .init(detectorArea: .rectangle)) {
        self.detector = detector
    }
    
    public func makeUIViewController(context: UIViewControllerRepresentableContext<BarcodeScannerView>) -> UIViewController {
        return BarcodeScannerViewController(detector: detector)
    }

    // swiftlint:disable:next no_empty_block
    public func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<BarcodeScannerView>) { }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject {
        var parent: BarcodeScannerView
        private var subscriptions = Set<AnyCancellable>()
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
            let detector = parent.detector
            
            if !detector.hasCamera {
                detector.setup()
            }
            self.parent.detector.statePublisher
                .sink { state in
                    switch state {
                    case .idle:
                        /// setup camera, can be called more than once
                        detector.setup()
                    case .ready, .scanning, .pausing, .batterySaving:
                        break
                    }
                }
                .store(in: &subscriptions)
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
        } else {
            let layer = CAGradientLayer()
            layer.colors = [UIColor.projectPrimary().cgColor, UIColor.white.cgColor]
            containerView.setupPreviewLayer(layer)
        }
        
        return containerView
    }
    
    public func updateUIView(_ uiView: ScannerContainerView, context: Context) {
        guard uiView.bounds.width > 0 && uiView.bounds.height > 0 else {
            return
        }
        
        uiView.updatePreviewLayerFrame()
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject {
        var parent: BarcodeScanner
        private var subscriptions = Set<AnyCancellable>()
        
        init(_ parent: BarcodeScanner) {
            self.parent = parent
            let detector = parent.detector
            
            if !detector.hasCamera {
                detector.setup()
            }
            
            self.parent.detector.statePublisher
                .sink { state in
                    switch state {
                    case .idle:
                        detector.setup()
                    case .ready, .scanning, .pausing, .batterySaving:
                        break
                    }
                }
                .store(in: &subscriptions)
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
