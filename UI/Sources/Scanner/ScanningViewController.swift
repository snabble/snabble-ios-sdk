//
//  ScanningViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SwiftUI
import AVFoundation
import SnabbleCore
import SnabbleAssetProviding
import CameraZoomWheel

public final class ZoomWheelController: UIHostingController<ZoomControl> {
    public init(zoomLevel: Binding<CGFloat>, steps: [ZoomStep]) {
        super.init(rootView: ZoomControl(zoomLevel: zoomLevel, steps: steps))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        view.layer.zPosition = 1
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        view.invalidateIntrinsicContentSize()
    }
}

public extension Notification.Name {
    static let snabbleShowScanConfirmation = Notification.Name("snabbleShowScanConfirmation")
    static let snabbleHideScanConfirmation = Notification.Name("snabbleHideScanConfirmation")
}

private enum ScannerLookup {
    case product(ScannedProduct)
    case coupon(Coupon, String)
    case failure(ProductLookupError)
}

public final class ScanningViewController: UIViewController, BarcodePresenting {
    private weak var spinner: UIActivityIndicatorView?

    private var messageView: ScanningMessageView?
    private var messageTopDistance: NSLayoutConstraint?

    private var scanConfirmationView: ScanConfirmationView?
    private var scanConfirmationViewBottom: NSLayoutConstraint?

    private let tapticFeedback = UINotificationFeedbackGenerator()

    private let productProvider: ProductProviding
    private let shoppingCart: ShoppingCart
    private let shop: Shop

    private var confirmationVisible = false
    private var productType: ProductType?

    private let hiddenConfirmationOffset: CGFloat = 310
    private var visibleConfirmationOffset: CGFloat {
        if self.pulleyViewController?.drawerPosition == .closed {
            return -16
        }

        let bottom = self.pulleyViewController?.drawerDistanceFromBottom
        return -(bottom?.distance ?? 0) - 16
    }

    private var visibleWheelOffset: CGFloat {
        if self.pulleyViewController?.drawerPosition == .closed {
            return 12
        }

        let bottom = self.pulleyViewController?.drawerDistanceFromBottom
        return -(bottom?.distance ?? 0) + 12
    }

    private var keyboardObserver: KeyboardObserver!
    private var barcodeDetector: BarcodeDetector
    private var torchButton: UIBarButtonItem?

    private weak var spinnerTimer: Timer?
    private weak var messageTimer: Timer?

    public weak var scannerDelegate: ScannerDelegate?

    public weak var zoomController: ZoomWheelController?
    private var zoomLevel: CGFloat {
        get {
            if UserDefaults.standard.object(forKey: BarcodeDetector.zoomValueKey) != nil {
                return CGFloat(UserDefaults.standard.float(forKey: BarcodeDetector.zoomValueKey))
            } else {
                return barcodeDetector.zoomFactor ?? 1.0
            }
        }
        set {
            barcodeDetector.zoomFactor = newValue
        }
    }
    
    private var wheelViewBottom: NSLayoutConstraint?

    public init(forCart cart: ShoppingCart, forShop shop: Shop, withDetector detector: BarcodeDetector) {
        let project = shop.project ?? .none

        self.shop = shop

        self.shoppingCart = cart

        self.productProvider = Snabble.shared.productProvider(for: project)

        self.barcodeDetector = detector
        self.barcodeDetector.scanFormats = project.scanFormats
        self.barcodeDetector.expectedBarcodeWidth = project.expectedBarcodeWidth

        super.init(nibName: nil, bundle: nil)

        self.barcodeDetector.delegate = self

        self.title = Asset.localizedString(forKey: "Snabble.Scanner.title")
        self.tabBarItem.image = Asset.image(named: "SnabbleSDK/icon-scan-inactive")
        self.tabBarItem.selectedImage = Asset.image(named: "SnabbleSDK/icon-scan-active")
        self.navigationItem.title = Asset.localizedString(forKey: "Snabble.Scanner.scanningTitle")
        
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidBeginEditing(_:)), name: .textFieldDidBeginEditing, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)

        if #available(iOS 15, *) {
            view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .systemGray
        spinner.hidesWhenStopped = true

        let scanConfirmationView = ScanConfirmationView(frame: .zero)
        scanConfirmationView.translatesAutoresizingMaskIntoConstraints = false
        scanConfirmationView.isHidden = true

        let messageView = ScanningMessageView(frame: .zero)
        messageView.translatesAutoresizingMaskIntoConstraints = false
        let msgTap = UITapGestureRecognizer(target: self, action: #selector(self.messageTapped(_:)))
        messageView.addGestureRecognizer(msgTap)

        let zoomSteps: [ZoomStep]
        
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            zoomSteps = camera.zoomSteps
        } else {
            zoomSteps = ZoomStep.defaultSteps
        }
        let controller = ZoomWheelController(
            zoomLevel: Binding(get: { self.zoomLevel }, set: { self.zoomLevel = $0}),
            steps: zoomSteps)

        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(controller)

        view.addSubview(spinner)
        view.addSubview(scanConfirmationView)
        view.addSubview(messageView)
        view.addSubview(controller.view)
        
        controller.didMove(toParent: self)
        self.zoomController = controller
        
        self.spinner = spinner
        self.messageView = messageView
        self.scanConfirmationView = scanConfirmationView

        NSLayoutConstraint.activate([
            spinner.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 40),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanConfirmationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scanConfirmationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scanConfirmationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanConfirmationView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).usingVariable(&scanConfirmationViewBottom),
            messageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageView.topAnchor.constraint(equalTo: view.topAnchor).usingVariable(&messageTopDistance),
            
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controller.view.heightAnchor.constraint(equalToConstant: 130),
            controller.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).usingVariable(&wheelViewBottom)
        ])

        self.view = view
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemGray
        
        scanConfirmationView?.delegate = self
        scanConfirmationViewBottom?.constant = hiddenConfirmationOffset
        wheelViewBottom?.constant = visibleWheelOffset
        
        self.messageTopDistance?.constant = -150
        messageView?.isHidden = true

        let torchButton = UIBarButtonItem(image: Asset.image(named: "SnabbleSDK/icon-light-inactive"), style: .plain, target: self, action: #selector(torchTapped(_:)))
        self.pulleyViewController?.navigationItem.leftBarButtonItem = torchButton
        self.torchButton = torchButton

        let searchButton = UIBarButtonItem(image: Asset.image(named: "SnabbleSDK/icon-entercode"), style: .plain, target: self, action: #selector(searchTapped(_:)))
        self.pulleyViewController?.navigationItem.rightBarButtonItem = searchButton
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.barcodeDetector.scannerWillAppear(on: self.view)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.keyboardObserver = KeyboardObserver(handler: self)

        self.scannerDelegate?.track(.viewScanner)
        if let spinner = spinner {
            self.view.bringSubviewToFront(spinner)
        }
        if let confirmationView = self.scanConfirmationView {
            self.view.bringSubviewToFront(confirmationView)
        }
        if let messageView = messageView {
            self.view.bringSubviewToFront(messageView)
        }
        self.zoomLevel = barcodeDetector.zoomFactor ?? 1
        if let zoomWheel = zoomController?.view {
            self.view.bringSubviewToFront(zoomWheel)
        }
        if !self.confirmationVisible && self.pulleyViewController?.drawerPosition != .open {
            self.barcodeDetector.resumeScanning()
        }
    }
    
    @objc
    func textFieldDidBeginEditing(_ notification: Notification) {
        guard let textField = notification.object as? UITextField else {
            return
        }
        if textField.tag == ShoppingCart.textFieldMagic {
            self.pulleyViewController?.setDrawerPosition(position: .open, animated: true)
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.barcodeDetector.scannerDidLayoutSubviews()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.barcodeDetector.pauseScanning()
        self.barcodeDetector.scannerWillDisappear()

        self.keyboardObserver = nil

        UIApplication.shared.isIdleTimerDisabled = false
        hideMessage()
    }

    // MARK: - called by the drawer
    func setOverlayOffset(_ offset: CGFloat) {
        self.barcodeDetector.setOverlayOffset(offset)
        wheelViewBottom?.constant = visibleWheelOffset
    }

    func resumeScanning() {
        self.barcodeDetector.resumeScanning()
    }

    func pauseScanning() {
        self.barcodeDetector.pauseScanning()
    }

    // MARK: - nav bar buttons
    @objc private func torchTapped(_ sender: Any) {
        let torchOn = self.barcodeDetector.toggleTorch()
        torchButton?.image = torchOn ? Asset.image(named: "SnabbleSDK/icon-light-active") : Asset.image(named: "SnabbleSDK/icon-light-inactive")
    }

    @objc private func searchTapped(_ sender: Any) {
        self.enterBarcode()
    }

    // MARK: - scan confirmation views
    private func showConfirmation(for scannedProduct: ScannedProduct, withCode scannedCode: String) {
        self.confirmationVisible = true

        self.scanConfirmationView?.present(withProduct: scannedProduct, withCode: scannedCode, forCart: self.shoppingCart)

        if self.scanConfirmationView?.needsPresentation ?? false {
            self.displayScanConfirmationView(hidden: false, setBottomOffset: self.productType != .userMustWeigh)
        } else {
            self.confirmationVisible = false
            self.scanConfirmationView?.addToCart()
        }

        NotificationCenter.default.post(name: .snabbleShowScanConfirmation, object: nil)
    }

    private var reopenDrawer: Bool = false
    
    private func displayScanConfirmationView(hidden: Bool, setBottomOffset: Bool = true) {
        if !hidden {
            reopenDrawer = self.pulleyViewController?.drawerPosition == .open
        }

        self.pulleyViewController?.setDrawerPosition(position: hidden ? .collapsed : .closed, animated: false)
        self.pulleyViewController?.allowsUserDrawerPositionChange = hidden

        self.confirmationVisible = !hidden

        self.zoomController?.view.isHidden = !hidden
        self.scanConfirmationView?.isHidden = false

        if setBottomOffset {
            self.scanConfirmationViewBottom?.constant = hidden ? self.hiddenConfirmationOffset : self.visibleConfirmationOffset
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0,
                           options: .curveEaseInOut,
                           animations: {
                                self.view.layoutIfNeeded()
                           },
                           completion: { _ in
                                self.scanConfirmationView?.isHidden = hidden
                           }
            )
        } else {
            self.scanConfirmationView?.isHidden = hidden
        }
    }
}

// MARK: - message display

extension ScanningViewController {
    func showMessage(_ message: ScanMessage) {
        showMessages([message])
    }

    func showMessages(_ messages: [ScanMessage]) {
        guard let firstMsg = messages.first else {
           return
        }

        let model = ScanningMessageView.Provider(messages: messages)
        messageView?.configure(with: model)

        self.messageView?.isHidden = false
        self.messageTopDistance?.constant = 0

        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }

        let text = messages.map { $0.text }.joined(separator: "\n\n")
        let seconds: TimeInterval?
        if let dismissTime = firstMsg.dismissTime {
            seconds = dismissTime > 0 ? dismissTime : nil
        } else {
            let factor = firstMsg.imageUrl == nil ? 1.0 : 3.0
            let minMillis = firstMsg.imageUrl == nil ? 2000 : 4000
            let millis = min(max(50 * text.count, minMillis), 7000)
            seconds = TimeInterval(millis) / 1000.0 * factor
        }

        if let seconds = seconds {
            self.messageTimer?.invalidate()
            self.messageTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
                self.hideMessage()
            }
        }
    }

    @objc private func messageTapped(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }

        self.hideMessage()
    }

    private func hideMessage() {
        self.messageTopDistance?.constant = -150

        UIView.animate(withDuration: 0.2,
                       animations: { self.view.layoutIfNeeded() },
                       completion: { _ in self.messageView?.isHidden = true })
    }
}

// MARK: - analytics delegate
extension ScanningViewController: AnalyticsDelegate {
    public func track(_ event: AnalyticsEvent) {
        self.scannerDelegate?.track(event)
    }
}

// MARK: - scanning confirmation delegate
extension ScanningViewController: ScanConfirmationViewDelegate {
    func closeConfirmation(forItem item: CartItem?) {
        guard self.scanConfirmationView?.needsPresentation ?? false else {
            if self.pulleyViewController?.drawerPosition != .open {
                self.barcodeDetector.resumeScanning()
            }
            return
        }
        
        let reopen = reopenDrawer
        
        self.displayScanConfirmationView(hidden: true)

        if let item = item {
            var messages = [ScanMessage]()
            if let msg = self.ageCheckRequired(for: item) {
                messages.append(msg)
            }
            if let msg = self.scannerDelegate?.scanMessage(for: SnabbleCI.project, self.shop, item.product) {
                messages.append(msg)
            }

            self.showMessages(messages)

            if let drawer = self.pulleyViewController?.drawerContentViewController as? ScannerDrawerViewController {
                drawer.markScannedProduct(item.product)
            }
        }

        if reopen {
            self.pulleyViewController?.setDrawerPosition(position: .open, animated: true)
        } else {
            self.barcodeDetector.resumeScanning()
        }
    }

    private func ageCheckRequired(for item: CartItem) -> ScanMessage? {
        let userAge = Snabble.userAge

        switch item.product.saleRestriction {
        case .none:
            return nil
        case .fsk:
            break
        case .age(let minAge):
            if userAge >= minAge {
                return nil
            }
        }

        return ScanMessage(Asset.localizedString(forKey: "Snabble.Scanner.scannedAgeRestrictedProduct"))
    }

    private func enterBarcode() {
        let barcodeEntryViewController = BarcodeEntryViewController(self.productProvider, self.shop.id, completion: self.handleScannedCode)
        barcodeEntryViewController.analyticsDelegate = scannerDelegate
        self.navigationController?.pushViewController(barcodeEntryViewController, animated: true)

        self.barcodeDetector.pauseScanning()
    }
}

// MARK: - scanning view delegate
extension ScanningViewController: BarcodeScanning {
    public func scannedCodeResult(_ result: BarcodeResult) {
        self.handleScannedCode(result.code, withFormat: result.format)
    }
}

extension ScanningViewController {
    private func scannedUnknown(messageText: String, code: String) {
        // Log.debug("scanned unknown code \(code)")
        self.tapticFeedback.notificationOccurred(.error)

        let message = ScanMessage(messageText)
        self.showMessage(message)
        self.scannerDelegate?.track(.scanUnknown(code))
    }

    private func handleScannedCode(_ scannedCode: String, withFormat format: ScanFormat?, withTemplate template: String? = nil) {
        self.spinnerTimer?.invalidate()
        self.spinnerTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            self.spinner?.startAnimating()
        }

        self.barcodeDetector.pauseScanning()

        self.lookupCode(scannedCode, withFormat: format, withTemplate: template) { scannedResult in
            self.spinnerTimer?.invalidate()
            self.spinner?.stopAnimating()

            let scannedProduct: ScannedProduct
            switch scannedResult {
            case .failure(let error):
                self.showScanLookupError(error, forCode: scannedCode)
                return
            case .product(let product):
                scannedProduct = product
            case .coupon(let coupon, let scannedCode):
                self.shoppingCart.addCoupon(coupon, scannedCode: scannedCode)
                NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
                let msg = Asset.localizedString(forKey: "Snabble.Scanner.couponAdded", arguments: coupon.name)
                self.showMessage(ScanMessage(msg))
                self.barcodeDetector.resumeScanning()
                return
            }

            let product = scannedProduct.product
            let embeddedData = scannedProduct.embeddedData

            // check for sale stop / notForSale
            if self.isSaleProhibited(of: product, scannedCode: scannedCode) {
                return
            }

            // handle scanning the shelf code of a pre-weighed product (no data or 0 encoded in the EAN)
            if product.type == .preWeighed && (embeddedData == nil || embeddedData == 0) {
                let msg = Asset.localizedString(forKey: "Snabble.Scanner.scannedShelfCode")
                self.scannedUnknown(messageText: msg, code: scannedCode)
                self.barcodeDetector.resumeScanning()
                return
            }

            self.tapticFeedback.notificationOccurred(.success)

            self.scannerDelegate?.track(.scanProduct(scannedProduct.transmissionCode ?? scannedCode))
            self.productType = product.type

            if product.bundles.isEmpty || scannedProduct.priceOverride != nil {
                self.showConfirmation(for: scannedProduct, withCode: scannedCode)
            } else {
                self.showBundleSelection(for: scannedProduct, withCode: scannedCode)
            }
        }
    }

    private func showScanLookupError(_ error: ProductLookupError, forCode scannedCode: String) {
        let errorMsg: String
        switch error {
        case .notFound: errorMsg = Asset.localizedString(forKey: "Snabble.Scanner.unknownBarcode")
        case .networkError: errorMsg = Asset.localizedString(forKey: "Snabble.Scanner.networkError")
        case .serverError: errorMsg = Asset.localizedString(forKey: "Snabble.Scanner.serverError")
        }

        self.scannedUnknown(messageText: errorMsg, code: scannedCode)
        self.barcodeDetector.resumeScanning()
    }

    private func isSaleProhibited(of product: Product, scannedCode: String) -> Bool {
        // check for sale stop
        if product.saleStop {
            self.showSaleStop()
            return true
        }

        // check for not-for-sale
        if product.notForSale {
            self.showNotForSale(for: product, withCode: scannedCode)
            return true
        }

        return false
    }

    private func showSaleStop() {
        self.tapticFeedback.notificationOccurred(.error)
        let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.SaleStop.ErrorMsg.title"),
                                      message: Asset.localizedString(forKey: "Snabble.SaleStop.ErrorMsg.scan"),
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default) { _ in
            self.barcodeDetector.resumeScanning()
        })

        self.present(alert, animated: true)
    }

    private func showNotForSale(for product: Product, withCode scannedCode: String) {
        self.tapticFeedback.notificationOccurred(.error)
        if let msg = self.scannerDelegate?.scanMessage(for: SnabbleCI.project, self.shop, product) {
            self.showMessage(msg)
        } else {
            self.scannedUnknown(messageText: Asset.localizedString(forKey: "Snabble.NotForSale.ErrorMsg.scan"), code: scannedCode)
        }
        self.barcodeDetector.resumeScanning()
    }

    private func showBundleSelection(for scannedProduct: ScannedProduct, withCode scannedCode: String) {
        let alert = UIAlertController(title: nil, message: Asset.localizedString(forKey: "Snabble.Scanner.BundleDialog.headline"), preferredStyle: .actionSheet)

        let product = scannedProduct.product
        alert.addAction(UIAlertAction(title: product.name, style: .default) { _ in
            self.showConfirmation(for: scannedProduct, withCode: scannedCode)
        })

        for bundle in product.bundles {
            alert.addAction(UIAlertAction(title: bundle.name, style: .default) { _ in
                let bundleCode = bundle.codes.first?.code
                let transmissionCode = bundle.codes.first?.transmissionCode ?? bundleCode
                let lookupCode = transmissionCode ?? scannedCode
                let specifiedQuantity = bundle.codes.first?.specifiedQuantity
                let scannedBundle = ScannedProduct(bundle, lookupCode, transmissionCode,
                                                   specifiedQuantity: specifiedQuantity)

                if self.isSaleProhibited(of: scannedBundle.product, scannedCode: scannedCode) {
                    return
                }
                self.showConfirmation(for: scannedBundle, withCode: transmissionCode ?? scannedCode)
            })
        }

        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.cancel"), style: .cancel) { _ in
            self.barcodeDetector.resumeScanning()
        })

        // HACK: set the action sheet buttons background
        if let alertContentView = alert.view.subviews.first?.subviews.first {
            for view in alertContentView.subviews {
                view.backgroundColor = .systemBackground
            }
        }

        self.present(alert, animated: true)
    }

    private func lookupCode(_ code: String,
                            withFormat format: ScanFormat?,
                            withTemplate template: String?,
                            completion: @escaping (ScannerLookup) -> Void ) {
        // if we were given a template from the barcode entry, use that to lookup the product directly
        if let template = template {
            return self.lookupProduct(for: code, withTemplate: template, priceOverride: nil, completion: completion)
        }

        // check override codes first
        let project = SnabbleCI.project
        if let match = CodeMatcher.matchOverride(code, project.priceOverrideCodes, project.id) {
            return self.productForOverrideCode(for: match, completion: completion)
        }

        // then, check our regular templates
        let matches = CodeMatcher.match(code, project.id)
        guard !matches.isEmpty else {
            return completion(.failure(.notFound))
        }

        let lookupCodes = matches.map { $0.lookupCode }
        let templates = matches.map { $0.template.id }
        let codes = Array(zip(lookupCodes, templates))

        self.productProvider.productBy(codes: codes, shopId: self.shop.id) { result in
            switch result {
            case .success(let lookupResult):
                guard let parseResult = matches.first(where: { $0.template.id == lookupResult.templateId }) else {
                    completion(.failure(.notFound))
                    return
                }

                let scannedCode = lookupResult.transmissionCode ?? code
                var newResult = ScannedProduct(lookupResult.product,
                                               parseResult.lookupCode,
                                               scannedCode,
                                               templateId: lookupResult.templateId,
                                               transmissionTemplateId: lookupResult.transmissionTemplateId,
                                               embeddedData: parseResult.embeddedData,
                                               encodingUnit: lookupResult.encodingUnit,
                                               referencePriceOverride: parseResult.referencePrice,
                                               specifiedQuantity: lookupResult.specifiedQuantity)

                if let decimalData = parseResult.embeddedDecimal {
                    var encodingUnit = lookupResult.product.encodingUnit
                    var embeddedData: Int?
                    let div = Int(pow(10.0, Double(decimalData.fractionDigits)))
                    if let enc = encodingUnit {
                        switch enc {
                        case .piece:
                            encodingUnit = .piece
                            embeddedData = decimalData.value / div
                        case .kilogram, .meter, .liter, .squareMeter:
                            encodingUnit = enc.fractionalUnit(div)
                            embeddedData = decimalData.value
                        case .gram, .millimeter, .milliliter:
                            embeddedData = decimalData.value
                        default:
                            Log.warn("unspecified conversion for embedded data: \(decimalData.value) \(enc)")
                        }
                    }

                    newResult = ScannedProduct(lookupResult.product, parseResult.lookupCode, scannedCode,
                                               templateId: lookupResult.templateId,
                                               transmissionTemplateId: lookupResult.transmissionTemplateId,
                                               embeddedData: embeddedData,
                                               encodingUnit: encodingUnit,
                                               referencePriceOverride: newResult.referencePriceOverride,
                                               specifiedQuantity: lookupResult.specifiedQuantity)
                }

                completion(.product(newResult))
            case .failure(let error):
                if error == .notFound {
                    if let gs1 = self.checkValidGS1(for: code) {
                        return self.productForGS1(gs1: gs1, originalCode: code, completion: completion)
                    }

                    // is this a valid coupon?
                    if let coupon = self.checkValidCoupon(for: code) {
                        return completion(.coupon(coupon, code))
                    }

                    return completion(.failure(.notFound))
                } else {
                    let event = AppEvent(scannedCode: code, codes: codes, project: project)
                    event.post()
                    completion(.failure(error))
                }
            }
        }
    }

    private func checkValidCoupon(for scannedCode: String) -> Coupon? {
        let project = SnabbleCI.project
        let validCoupons = project.printedCoupons

        for coupon in validCoupons {
            for code in coupon.codes ?? [] {
                let result = CodeMatcher.match(scannedCode, project.id)
                if result.first(where: { $0.template.id == code.template && $0.lookupCode == code.code }) != nil {
                    return coupon
                }
            }
        }

        return nil
    }

    private func checkValidGS1(for code: String) -> GS1Code? {
        let gs1 = GS1Code(code)
        if gs1.gtin != nil {
            return gs1
        }
        return nil
    }

    private func productForGS1(gs1: GS1Code,
                               originalCode: String,
                               completion: @escaping (ScannerLookup) -> Void ) {
        guard let gtin = gs1.gtin else {
            return completion(.failure(.notFound))
        }

        let codes = [(gtin, CodeTemplate.defaultName)]
        self.productProvider.productBy(codes: codes, shopId: self.shop.id) { result in
            switch result {
            case .success(let lookupResult):
                let priceDigits = SnabbleCI.project.decimalDigits
                let roundingMode = SnabbleCI.project.roundingMode
                let (embeddedData, encodingUnit) = gs1.getEmbeddedData(for: lookupResult.encodingUnit, priceDigits, roundingMode)
                let result = ScannedProduct(lookupResult.product,
                                            gtin,
                                            originalCode,
                                            templateId: CodeTemplate.defaultName,
                                            transmissionTemplateId: nil,
                                            embeddedData: embeddedData,
                                            encodingUnit: encodingUnit,
                                            referencePriceOverride: nil,
                                            specifiedQuantity: lookupResult.specifiedQuantity)
                completion(.product(result))
            case .failure(let error):
                let event = AppEvent(scannedCode: originalCode, codes: codes, project: SnabbleCI.project)
                event.post()
                completion(.failure(error))
            }
        }
    }

    private func productForOverrideCode(for match: OverrideLookup, completion: @escaping (ScannerLookup) -> Void ) {
        let code = match.lookupCode

        if let template = match.lookupTemplate {
            return self.lookupProduct(for: code, withTemplate: template, priceOverride: match.embeddedData, completion: completion)
        }

        let matches = CodeMatcher.match(code, SnabbleCI.project.id)

        guard !matches.isEmpty else {
            return completion(.failure(.notFound))
        }

        let lookupCodes = matches.map { $0.lookupCode }
        let templates = matches.map { $0.template.id }
        let codes = Array(zip(lookupCodes, templates))
        self.productProvider.productBy(codes: codes, shopId: self.shop.id) { result in
            switch result {
            case .success(let lookupResult):
                let newResult = ScannedProduct(lookupResult.product, code, match.transmissionCode,
                                               templateId: lookupResult.templateId,
                                               transmissionTemplateId: lookupResult.transmissionTemplateId,
                                               embeddedData: nil,
                                               encodingUnit: .price,
                                               specifiedQuantity: lookupResult.specifiedQuantity,
                                               priceOverride: match.embeddedData)
                completion(.product(newResult))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func lookupProduct(for code: String, withTemplate template: String, priceOverride: Int?, completion: @escaping (ScannerLookup) -> Void ) {
        let codes = [(code, template)]
        self.productProvider.productBy(codes: codes, shopId: self.shop.id) { result in
            switch result {
            case .success(let lookupResult):
                let transmissionCode = lookupResult.product.codes[0].transmissionCode
                let scannedProduct: ScannedProduct
                if let priceOverride = priceOverride {
                    scannedProduct = ScannedProduct(lookupResult.product, code, transmissionCode,
                                                    templateId: template,
                                                    transmissionTemplateId: lookupResult.transmissionTemplateId,
                                                    embeddedData: nil,
                                                    encodingUnit: .price,
                                                    referencePriceOverride: nil,
                                                    specifiedQuantity: lookupResult.specifiedQuantity,
                                                    priceOverride: priceOverride)
                } else {
                    scannedProduct = ScannedProduct(lookupResult.product, code, transmissionCode,
                                                    templateId: template,
                                                    transmissionTemplateId: lookupResult.transmissionTemplateId,
                                                    specifiedQuantity: lookupResult.specifiedQuantity)
                }
                completion(.product(scannedProduct))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

}

extension ScanningViewController: KeyboardHandling {
    public func keyboardWillShow(_ info: KeyboardInfo) {
        self.scanConfirmationViewBottom?.constant = -(info.keyboardHeight - 48)
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    public func keyboardWillHide(_ info: KeyboardInfo) {
        self.scanConfirmationViewBottom?.constant = self.confirmationVisible ? self.visibleConfirmationOffset : self.hiddenConfirmationOffset
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

}
