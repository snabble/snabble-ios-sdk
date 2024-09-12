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

class BarcodeScannerViewController: UIViewController {
    let manager: BarcodeManager
    let logger = Logger(subsystem: "ScanAndGo", category: "BarcodeScannerViewController")
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(manager: BarcodeManager) {
        self.manager = manager
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
        
        if let previewLayer = manager.barcodeDetector.previewLayer {
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

struct BarcodeScannerView: UIViewControllerRepresentable {
    @SwiftUI.Environment(\.safeAreaInsets) var insets
    
    let manager: BarcodeManager
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<BarcodeScannerView>) -> UIViewController {
        return BarcodeScannerViewController(manager: manager)
    }
    // swiftlint:disable:next no_empty_block
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<BarcodeScannerView>) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject {
        var parent: BarcodeScannerView
        private var subscriptions = Set<AnyCancellable>()
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
            let manager = parent.manager
            
            if !manager.barcodeDetector.hasCamera {
                manager.barcodeDetector.setup()
            }
            self.parent.manager.barcodeDetector.$state
                .sink { state in
                    switch state {
                    case .idle:
                        /// setup camera, can be called more than once
                        manager.barcodeDetector.setup()
                    case .ready, .scanning, .pausing, .batterySaving:
                        break
                    }
                }
                .store(in: &subscriptions)
        }
    }
}
