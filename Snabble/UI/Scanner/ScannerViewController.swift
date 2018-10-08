//
//  ScannerViewController.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit
import AVFoundation

public protocol ScannerDelegate: AnalyticsDelegate, MessageDelegate {
    func closeScanningView()
}

extension ScanFormat {
    var avType: AVMetadataObject.ObjectType {
        switch self {
        case .ean8: return .ean8
        case .ean13: return .ean13
        case .code128: return .code128
        case .itf14: return .itf14
        case .code39: return .code39
        case .qr: return .qr
        case .dataMatrix: return .dataMatrix
        }
    }
}

public class ScannerViewController: UIViewController {

    @IBOutlet private weak var spinner: UIActivityIndicatorView!

    private var scanningView: ScanningView!
    private var scanConfirmationView: ScanConfirmationView!
    private var scanConfirmationViewBottom: NSLayoutConstraint!

    private var infoView: ScannerInfoView!

    private var productProvider: ProductProvider
    private var shoppingCart: ShoppingCart
    private var shop: Shop

    private var lastScannedCode = ""
    private var confirmationVisible = false
    private var productType: ProductType?
    
    private var hiddenConfirmationOffset: CGFloat = 310
    private var keyboardObserver: KeyboardObserver!
    private var objectTypes: [AVMetadataObject.ObjectType] = [ .ean8, .ean13, .code128 ]
    private weak var delegate: ScannerDelegate!
    private var timer: Timer?

    public init(_ project: Project, _ cart: ShoppingCart, _ shop: Shop, delegate: ScannerDelegate) {
        self.productProvider = SnabbleAPI.productProvider(for: project)
        self.shoppingCart = cart
        self.shop = shop
        self.objectTypes = project.scanFormats.map { $0.avType }

        super.init(nibName: nil, bundle: Snabble.bundle)

        self.delegate = delegate

        self.title = "Snabble.Scanner.title".localized()
        self.tabBarItem.image = UIImage.fromBundle("icon-scan")
        self.navigationItem.title = "Snabble.Scanner.scanningTitle".localized()

        let infoIcon = UIImage.fromBundle("icon-info")?.recolored(with: .white)
        let infoButton = UIBarButtonItem(image: infoIcon, style: .plain, target: self, action: #selector(self.infoButtonTapped(_:)))
        self.navigationItem.leftBarButtonItem = infoButton
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var firstTimeInfoShown: Bool {
        get { return UserDefaults.standard.bool(forKey: "snabble.scanner.firstTimeInfoShown") }
        set { UserDefaults.standard.set(newValue, forKey: "snabble.scanner.firstTimeInfoShown") }
    }

    private var firstScanComplete: Bool {
        get { return UserDefaults.standard.bool(forKey: "snabble.scanner.firstScanComplete") }
        set { UserDefaults.standard.set(newValue, forKey: "snabble.scanner.firstScanComplete") }
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

        self.infoView = ScannerInfoView()
        self.infoView.delegate = self
        self.infoView.translatesAutoresizingMaskIntoConstraints = false
        self.scanningView.addSubview(self.infoView)
        self.infoView.leadingAnchor.constraint(equalTo: self.scanningView.leadingAnchor, constant: 16).isActive = true
        self.infoView.trailingAnchor.constraint(equalTo: self.scanningView.trailingAnchor, constant: -16).isActive = true
        self.infoView.centerXAnchor.constraint(equalTo: self.scanningView.centerXAnchor).isActive = true
        self.infoView.bottomAnchor.constraint(equalTo: self.scanningView.bottomAnchor, constant: -16).isActive = true
        self.infoView.isHidden = self.firstTimeInfoShown

        var scannerConfig = ScanningViewConfig()
        
        scannerConfig.torchButtonTitle = "Snabble.Scanner.torchButton".localized()
        scannerConfig.torchButtonImage = UIImage.fromBundle("icon-light")?.recolored(with: .white)
        scannerConfig.enterButtonTitle = "Snabble.Scanner.enterCodeButton".localized()
        scannerConfig.enterButtonImage = UIImage.fromBundle("icon-entercode")?.recolored(with: .white)
        scannerConfig.textColor = .white
        scannerConfig.metadataObjectTypes = self.objectTypes
        scannerConfig.reticleCornerRadius = 3

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
        if self.firstTimeInfoShown {
            self.scanningView.initializeCamera()
            self.scanningView.startScanning()
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.scanningView.stopScanning()
        self.hideScanConfirmationView(true)
        self.infoView.isHidden = true
    }

    /// reset `productProvider` and `shoppingCart` when switching between projects
    public func reset(_ project: Project, _ cart: ShoppingCart) {
        self.productProvider = SnabbleAPI.productProvider(for: project)
        self.shoppingCart = cart
        self.objectTypes = project.scanFormats.map { $0.avType }
        self.scanningView?.setScanObjects(self.objectTypes)

        // avoid camera permission query if this is called before we've ever been on-screen
        if self.scanningView != nil {
            self.closeConfirmation()
            self.navigationController?.popToRootViewController(animated: false)
        }
    }

    // MARK: - scan confirmation views
    
    private func showConfirmation(for product: Product, _ code: String) {
        self.confirmationVisible = true
        self.scanConfirmationView.present(product, cart: self.shoppingCart, code: code)

        self.scanningView.stopScanning()
        self.hideScanConfirmationView(false)
    }
    
    private func hideScanConfirmationView(_ hide: Bool) {
        guard self.view.window != nil else {
            return
        }
        
        self.confirmationVisible = !hide
        var offset: CGFloat = -16
        if self.scanConfirmationView.isFirstResponder {
            offset = self.scanConfirmationViewBottom.constant
        }
        self.scanConfirmationViewBottom.constant = hide ? self.hiddenConfirmationOffset : offset
        
        self.scanningView.bottomBarHidden = !hide
        self.scanningView.reticleHidden = !hide

        UIView.animate(withDuration: 0.12) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func infoButtonTapped(_ sender: Any) {
        if self.confirmationVisible {
            return
        }

        self.showInfo()
    }
}

// MARK: - info delegate
extension ScannerViewController: ScannerInfoDelegate {

    func showInfo() {
        self.scanningView.stopScanning()
        self.infoView.isHidden = false
        self.scanningView.reticleHidden = true
    }

    func close() {
        self.infoView.isHidden = true
        self.firstTimeInfoShown = true
        self.scanningView.reticleHidden = false
        self.scanningView.initializeCamera()
        self.scanningView.startScanning()
    }
}

// MARK: - analytics delegate
extension ScannerViewController: AnalyticsDelegate {
    public func track(_ event: AnalyticsEvent) {
        self.delegate.track(event)
    }
}

extension ScannerViewController: MessageDelegate {
    public func showInfoMessage(_ message: String) {
        self.delegate.showInfoMessage(message)
    }

    public func showWarningMessage(_ message: String) {
        self.delegate.showWarningMessage(message)
    }
}

// MARK: - scanning confirmation delegate
extension ScannerViewController: ScanConfirmationViewDelegate {
    func closeConfirmation() {
        self.hideScanConfirmationView(true)

        if !self.firstScanComplete {
            self.firstScanComplete = true

            let title = String(format: "Snabble.Hints.title".localized(), self.shop.name)
            let msg = "Snabble.Hints.closedBags".localized()
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Snabble.Hints.continueScanning".localized(), style: .default) { action in
                self.scanningView.startScanning()
            })
            self.present(alert, animated: false)
        } else {
            self.scanningView.startScanning()
        }
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
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
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
        print("scanned unknown code \(code)")
        self.delegate.showWarningMessage(msg)
        self.delegate.track(.scanUnknown(code))

        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
            self.lastScannedCode = ""
        }
    }

    private func handleScannedCode(_ scannedCode: String) {
        self.lastScannedCode = scannedCode

        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { timer in
            self.spinner.startAnimating()
        }

        self.scanningView.stopScanning()

        self.productForCode(scannedCode) { product, code in
            self.timer?.invalidate()
            self.timer = nil
            self.spinner.stopAnimating()

            guard let product = product else {
                self.scannedUnknown("Snabble.Scanner.unknownBarcode".localized(), scannedCode)
                self.scanningView.startScanning()
                return
            }

            let ean = EAN.parse(scannedCode, SnabbleUI.project)
            // handle scanning the shelf code of a pre-weighed product
            if product.type == .preWeighed && ean?.embeddedData == nil {
                let msg = "Snabble.Scanner.scannedShelfCode".localized()
                self.scannedUnknown(msg, code)
                self.scanningView.startScanning()
                return
            }

            self.delegate.track(.scanProduct(code))
            self.productType = product.type
            self.lastScannedCode = ""

            if product.bundles.count > 0 {
                self.showBundleSelection(for: product, code)
            } else {
                self.showConfirmation(for: product, code)
            }
        }
    }

    private func showBundleSelection(for product: Product, _ code: String) {
        let alert = UIAlertController(title: nil, message: "Snabble.Scanner.BundleDialog.headline".localized(), preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: product.name, style: .default) { action in
            self.showConfirmation(for: product, code)
        })

        for bundle in product.bundles {
            alert.addAction(UIAlertAction(title: bundle.name, style: .default) { action in
                let bundleCode = bundle.scannableCodes.first ?? ""
                let transmissionCode = bundle.transmissionCodes[bundleCode] ?? bundleCode
                self.showConfirmation(for: bundle, transmissionCode)
            })
        }

        alert.addAction(UIAlertAction(title: "Snabble.Cancel".localized(), style: .cancel) { action in
            self.scanningView.startScanning()
        })

        // HACK: set the action sheet buttons background
        if let alertContentView = alert.view.subviews.first?.subviews.first {
            for view in alertContentView.subviews { //This is main catch
                view.backgroundColor = .white
            }
        }

        self.scanningView.stopScanning()
        self.present(alert, animated: true)
    }

    private func productForCode(_ code: String, completion: @escaping (Product?, String) -> () ) {
        if let ean = EAN.parse(code, SnabbleUI.project), ean.hasEmbeddedData, ean.encoding != .edekaProductPrice {
            if SnabbleUI.project.verifyInternalEanChecksum {
                guard
                    let ean13 = ean as? EAN13,
                    ean13.priceFieldOk()
                else {
                    completion(nil, "")
                    return
                }
            }

            self.productProvider.productByWeighItemId(ean.codeForLookup, self.shop.id) { product, error in
                completion(product, code)
            }
        } else {
            if code.hasPrefix("97") && code.count == 22 {
                let startIndex = code.startIndex
                let embeddedCode = String(code[code.index(startIndex, offsetBy: 2)..<code.index(startIndex, offsetBy: 15)])
                let embeddedPrice = Int(String(code[code.index(startIndex, offsetBy: 16)..<code.index(startIndex, offsetBy: 21)])) ?? 0
                self.productProvider.productByScannableCode(embeddedCode, self.shop.id) { result, error in
                    if let result = result {
                        let template = "2417000000000"
                        let newCode = EAN13.embedDataInEan(template, data: embeddedPrice)
                        completion(result.product, newCode)
                    } else {
                        completion(nil, "")
                    }
                }
            } else {
                self.productProvider.productByScannableCode(code, self.shop.id) { result, error in
                    if let result = result {
                        completion(result.product, result.code)
                    } else {
                        completion(nil, "")
                    }
                }
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
        self.scanConfirmationViewBottom.constant = -info.keyboardHeight - offset

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
