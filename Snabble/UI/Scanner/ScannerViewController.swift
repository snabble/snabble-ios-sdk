//
//  ScannerViewController.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit
import AVFoundation

public protocol ScannerDelegate: AnalyticsDelegate, MessageDelegate {
    func closeScanningView()
    func gotoCheckout()
}

public class ScannerViewController: UIViewController {

    @IBOutlet private weak var spinner: UIActivityIndicatorView!

    private var scanningView: ScanningView!
    private var scanConfirmationView: ScanConfirmationView!
    private var scanConfirmationViewBottom: NSLayoutConstraint!

    private var productProvider: ProductProvider!
    private var shoppingCart: ShoppingCart!

    private var lastScannedCode = ""
    private var confirmationVisible = false
    private var productType: ProductType?
    
    private var hiddenConfirmationOffset: CGFloat = 310
    private var keyboardObserver: KeyboardObserver!
    private var objectTypes: [AVMetadataObject.ObjectType] = [ .ean8, .ean13, .code128 ]
    private weak var delegate: ScannerDelegate!
    private var timer: Timer?
    
    public init(_ productProvider: ProductProvider, _ cart: ShoppingCart, delegate: ScannerDelegate, objectTypes: [AVMetadataObject.ObjectType]? = nil) {
        super.init(nibName: nil, bundle: Snabble.bundle)

        self.productProvider = productProvider
        self.shoppingCart = cart
        self.delegate = delegate
        if let objectTypes = objectTypes {
            self.objectTypes = objectTypes
        }

        self.title = "Snabble.Scanner.title".localized()
        self.tabBarItem.image = UIImage.fromBundle("icon-scan")
        self.navigationItem.title = "Snabble.Scanner.scanningTitle".localized()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black

        self.scanningView = ScanningView()
        self.scanningView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.scanningView)
        self.scanningView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.scanningView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.scanningView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.scanningView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true

        self.scanConfirmationView = ScanConfirmationView()
        self.scanConfirmationView.translatesAutoresizingMaskIntoConstraints = false
        self.scanningView.addSubview(self.scanConfirmationView)
        self.scanConfirmationView.leadingAnchor.constraint(equalTo: self.scanningView.leadingAnchor, constant: 16).isActive = true
        self.scanConfirmationView.trailingAnchor.constraint(equalTo: self.scanningView.trailingAnchor, constant: -16).isActive = true
        self.scanConfirmationView.centerXAnchor.constraint(equalTo: self.scanningView.centerXAnchor).isActive = true
        let bottom = self.scanConfirmationView.bottomAnchor.constraint(equalTo: self.scanningView.bottomAnchor)
        bottom.isActive = true
        bottom.constant = self.hiddenConfirmationOffset
        self.scanConfirmationViewBottom = bottom

        var scannerConfig = ScanningViewConfig()
        
        scannerConfig.torchButtonTitle = "Snabble.Scanner.torchButton".localized()
        scannerConfig.torchButtonImage = UIImage.fromBundle("icon-light")?.recolored(with: .white)
        scannerConfig.enterButtonTitle = "Snabble.Scanner.enterCodeButton".localized()
        scannerConfig.enterButtonImage = UIImage.fromBundle("icon-entercode")?.recolored(with: .white)
        scannerConfig.textColor = .white
        scannerConfig.metadataObjectTypes = self.objectTypes

        scannerConfig.delegate = self

        self.scanningView.setup(with: scannerConfig)

        self.scanConfirmationView.delegate = self

        self.keyboardObserver = KeyboardObserver(handler: self)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.delegate.track(.viewScanner)
        self.scanningView.startScanning()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.scanningView.stopScanning()
        self.hideScanConfirmationView(true)
    }

    /// reset `productProvider` and `shoppingCart` when switching between projects
    public func reset(_ productProvider: ProductProvider, _ cart: ShoppingCart) {
        self.productProvider = productProvider
        self.shoppingCart = cart

        self.closeConfirmation()
        self.navigationController?.popToRootViewController(animated: false)
    }
    
    // MARK: - scan confirmation views
    
    private func showConfirmation(for product: Product, _ ean: EANCode) {
        self.scanConfirmationView.present(product, cart: self.shoppingCart, ean: ean)
        
        self.scanningView.stopScanning()
        self.hideScanConfirmationView(false)
    }
    
    private func hideScanConfirmationView(_ hide: Bool) {
        guard self.view.window != nil else {
            return
        }
        
        self.confirmationVisible = !hide
        self.scanConfirmationViewBottom.constant = hide ? self.hiddenConfirmationOffset : -16
        
        self.scanningView.bottomBarHidden = !hide
        self.scanningView.reticleHidden = !hide

        UIView.animate(withDuration: 0.12) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - analytics delegate
extension ScannerViewController: AnalyticsDelegate {
    public func showInfoMessage(_ message: String) {
        //
    }

    public func showWarningMessage(_ message: String) {
        //
    }

    public func track(_ event: AnalyticsEvent) {
        self.delegate.track(event)
    }
}

// MARK: - scanning confirmation delegate
extension ScannerViewController: ScanConfirmationViewDelegate {
    func closeConfirmation() {
        self.hideScanConfirmationView(true)
        self.scanningView.startScanning()
    }

    func gotoCheckout() {
        self.delegate.gotoCheckout()
    }
}

// MARK: - scanning view delegate
extension ScannerViewController: ScanningViewDelegate {
    public func closeScanningView() {
        self.delegate.closeScanningView()
    }

    public func requestCameraPermission(currentStatus: AVAuthorizationStatus) {
        switch currentStatus {
        case .restricted, .denied:
            let msg = "Snabble.Scanner.Camera.allowAccess".localized()
            let alert = UIAlertController(title: "Snabble.Scanner.Camera.accessDenied".localized(), message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Snabble.Cancel".localized(), style: .cancel) { action in
                self.closeScanningView()
            })
            alert.addAction(UIAlertAction(title: "Snabble.Settings".localized(), style: .default) { action in
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
                self.closeScanningView()
            })
            self.present(alert, animated: true)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.scanningView.startScanning()
                    } else {
                        self.closeScanningView()
                    }
                }
            }
        default:
            assertionFailure("unhandled av auth status \(currentStatus.rawValue)")
            break
        }
    }

    public func noCameraFound() {
        print("no camera found")
    }

    public func enterBarcode() {
        let barcodeEntry = BarcodeEntryViewController(self.productProvider, delegate: self.delegate, completion: self.manuallyEnteredCode)
        self.navigationController?.pushViewController(barcodeEntry, animated: true)
        
        self.scanningView.stopScanning()
    }
    
    public func scannedCode(_ code: String) {
        if code == self.lastScannedCode {
            return
        }
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        self.handleScannedCode(code)
    }
}

extension ScannerViewController {

    private func scannedUnknown(_ msg: String, _ code: String) {
        self.delegate.showWarningMessage(msg)
        self.delegate.track(.scanUnknown(code))
    }

    private func handleScannedCode(_ code: String) {
        self.lastScannedCode = code

        guard let ean = EAN.parse(code) else {
            self.scannedUnknown("Snabble.Scanner.unknownBarcode".localized(), code)
            return
        }

        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { timer in
            self.spinner.startAnimating()
        }

        self.scanningView.stopScanning()

        self.productForEan(ean) { product in
            self.timer?.invalidate()
            self.timer = nil
            self.spinner.stopAnimating()

            guard let product = product else {
                self.scannedUnknown("Snabble.Scanner.unknownBarcode".localized(), code)
                self.scanningView.startScanning()
                return
            }

            // handle scanning the shelf code of a pre-weighed product
            if product.type == .preWeighed && ean.embeddedData == nil {
                let msg = "Snabble.Scanner.scannedShelfCode".localized()
                self.scannedUnknown(msg, code)
                self.scanningView.startScanning()
                return
            }

            self.delegate.track(.scanProduct(code))

            self.productType = product.type
            self.showConfirmation(for: product, ean)
            self.lastScannedCode = ""
        }
    }

    private func productForEan(_ ean: EANCode, completion: @escaping (Product?) -> () ) {
        if ean.hasEmbeddedData {
            self.productProvider.productByWeighItemId(ean.codeForLookup, forceDownload: false) { product, error in
                completion(product)
            }
        } else {
            self.productProvider.productByScannableCode(ean.code, forceDownload: false) { product, error in
                completion(product)
            }
        }
    }

    private func manuallyEnteredCode(_ code: String?) {
        // print("entered \(code)")
        if let code = code {
            self.handleScannedCode(code)
        }
    }

}

extension ScannerViewController: KeyboardHandling {

    public func keyboardWillShow(_ info: KeyboardInfo) {
        if !self.confirmationVisible {
            return
        }

        let offset: CGFloat = self.productType == .singleItem ? 104 : 0
        self.scanConfirmationViewBottom.constant += info.keyboardHeight - offset

        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    public func keyboardWillHide(_ info: KeyboardInfo) {
        if !self.confirmationVisible {
            return
        }

        let offset: CGFloat = self.productType == .singleItem ? 104 : 0
        self.scanConfirmationViewBottom.constant -= info.keyboardHeight - offset

        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

}
