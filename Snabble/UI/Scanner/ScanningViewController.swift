//
//  ScanningViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import AVFoundation

public extension Notification.Name {
    static let snabbleShowScanConfirmation = Notification.Name("snabbleShowScanConfirmation")
    static let snabbleHideScanConfirmation = Notification.Name("snabbleHideScanConfirmation")
}

private enum ScannerLookup {
    case product(ScannedProduct)
    case coupon(Coupon, String)
    case failure(ProductLookupError)
}

final class ScanningViewController: UIViewController {
    @IBOutlet private var spinner: UIActivityIndicatorView!

    @IBOutlet private var messageImage: UIImageView!
    @IBOutlet private var messageImageWidth: NSLayoutConstraint!
    @IBOutlet private var messageSpinner: UIActivityIndicatorView!
    @IBOutlet private var messageWrapper: UIView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageSeparatorHeight: NSLayoutConstraint!
    @IBOutlet private var messageTopDistance: NSLayoutConstraint!

    private var scanConfirmationView: ScanConfirmationView?
    private var scanConfirmationViewBottom: NSLayoutConstraint?
    private let tapticFeedback = UINotificationFeedbackGenerator()

    private let productProvider: ProductProvider
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

    private var keyboardObserver: KeyboardObserver!
    private var barcodeDetector: BarcodeDetector
    private var customAppearance: CustomAppearance?
    private var torchButton: UIBarButtonItem?

    private var lastScannedCode: String?

    private weak var lastScanTimer: Timer?
    private weak var spinnerTimer: Timer?
    private weak var messageTimer: Timer?

    private var msgHidden = true

    public weak var scannerDelegate: ScannerDelegate?

    public init(_ cart: ShoppingCart, _ shop: Shop, _ detector: BarcodeDetector) {
        let project = shop.project ?? .none

        self.shop = shop

        self.shoppingCart = cart

        self.productProvider = SnabbleAPI.productProvider(for: project)

        self.barcodeDetector = detector
        self.barcodeDetector.scanFormats = project.scanFormats
        self.barcodeDetector.expectedBarcodeWidth = project.expectedBarcodeWidth

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.barcodeDetector.delegate = self

        self.title = L10n.Snabble.Scanner.title
        self.tabBarItem.image = Asset.SnabbleSDK.iconScanInactive.image
        self.tabBarItem.selectedImage = Asset.SnabbleSDK.iconScanActive.image
        self.navigationItem.title = L10n.Snabble.Scanner.scanningTitle

        SnabbleUI.registerForAppearanceChange(self)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .darkGray

        let scanConfirmationView = ScanConfirmationView()
        if let custom = self.customAppearance {
            scanConfirmationView.setCustomAppearance(custom)
        }
        scanConfirmationView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scanConfirmationView)
        scanConfirmationView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16).isActive = true
        scanConfirmationView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16).isActive = true
        scanConfirmationView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        scanConfirmationView.delegate = self
        scanConfirmationView.isHidden = true

        let bottom = scanConfirmationView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        bottom.isActive = true
        bottom.constant = self.hiddenConfirmationOffset

        self.scanConfirmationViewBottom = bottom
        self.scanConfirmationView = scanConfirmationView

        self.messageSeparatorHeight.constant = 1.0 / UIScreen.main.scale

        let msgTap = UITapGestureRecognizer(target: self, action: #selector(self.messageTapped(_:)))
        self.messageWrapper.addGestureRecognizer(msgTap)
        self.messageTopDistance.constant = -150
        self.messageWrapper.isHidden = true

        let torchButton = UIBarButtonItem(image: Asset.SnabbleSDK.iconLightInactive.image, style: .plain, target: self, action: #selector(torchTapped(_:)))
        self.pulleyViewController?.navigationItem.leftBarButtonItem = torchButton
        self.torchButton = torchButton

        let searchButton = UIBarButtonItem(image: Asset.SnabbleSDK.iconEntercode.image, style: .plain, target: self, action: #selector(searchTapped(_:)))
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
        self.view.bringSubviewToFront(self.spinner)

        self.barcodeDetector.resumeScanning()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.barcodeDetector.scannerDidLayoutSubviews()

        self.view.bringSubviewToFront(self.messageWrapper)
        if let confirmationView = self.scanConfirmationView {
            self.view.bringSubviewToFront(confirmationView)
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.displayScanConfirmationView(hidden: true)

        self.barcodeDetector.pauseScanning()
        self.barcodeDetector.scannerWillDisappear()

        self.keyboardObserver = nil

        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - called by the drawer
    func setOverlayOffset(_ offset: CGFloat) {
        self.barcodeDetector.setOverlayOffset(offset)
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
        torchButton?.image = torchOn ? Asset.SnabbleSDK.iconLightActive.image : Asset.SnabbleSDK.iconLightInactive.image
    }

    @objc private func searchTapped(_ sender: Any) {
        self.enterBarcode()
    }

    // MARK: - scan confirmation views
    private func showConfirmation(for scannedProduct: ScannedProduct, _ scannedCode: String) {
        self.confirmationVisible = true
        self.scanConfirmationView?.present(scannedProduct, scannedCode, cart: self.shoppingCart)

        self.displayScanConfirmationView(hidden: false, setBottomOffset: self.productType != .userMustWeigh)

        NotificationCenter.default.post(name: .snabbleShowScanConfirmation, object: nil)
    }

    private func displayScanConfirmationView(hidden: Bool, setBottomOffset: Bool = true) {
        if self.pulleyViewController?.supportedDrawerPositions().contains(.collapsed) == true {
            self.pulleyViewController?.setDrawerPosition(position: hidden ? .collapsed : .closed, animated: true)
        }

        self.confirmationVisible = !hidden

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

        let text: String
        if let attributedString = firstMsg.attributedString {
            text = firstMsg.text
            self.messageLabel.text = nil
            self.messageLabel.attributedText = attributedString
        } else {
            text = messages.map { $0.text }.joined(separator: "\n\n")
            self.messageLabel.text = text
        }
        self.messageWrapper.isHidden = false
        self.messageTopDistance.constant = 0

        if let imgUrl = messages.first?.imageUrl, let url = URL(string: imgUrl) {
            self.messageImageWidth.constant = 80
            self.loadMessageImage(url)
        } else {
            self.messageImageWidth.constant = 0
            self.messageImage.image = nil
        }

        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }

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
        self.messageTopDistance.constant = -150

        UIView.animate(withDuration: 0.2,
                       animations: { self.view.layoutIfNeeded() },
                       completion: { _ in self.messageWrapper.isHidden = true })
    }

    private func loadMessageImage(_ url: URL) {
        let session = URLSession.shared
        self.messageSpinner.startAnimating()
        let task = session.dataTask(with: url) { data, _, _ in
            if let data = data, let img = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.messageSpinner.stopAnimating()
                    self.messageImage.image = img
                }
            }
        }
        task.resume()
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
    func closeConfirmation(_ item: CartItem?) {
        self.displayScanConfirmationView(hidden: true)
        self.startLastScanTimer()

        if let item = item {
            var messages = [ScanMessage]()
            if let msg = self.ageCheckRequired(item) {
                messages.append(msg)
            }
            if let msg = self.scannerDelegate?.scanMessage(for: SnabbleUI.project, self.shop, item.product) {
                messages.append(msg)
            }

            self.showMessages(messages)

            if let drawer = self.pulleyViewController?.drawerContentViewController as? ScannerDrawerViewController {
                drawer.markScannedProduct(item.product)
            }
        }

        self.lastScannedCode = nil
        self.barcodeDetector.resumeScanning()
    }

    private func ageCheckRequired(_ item: CartItem) -> ScanMessage? {
        let userAge = SnabbleAPI.appUserData?.age ?? 0

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

        return ScanMessage(L10n.Snabble.Scanner.scannedAgeRestrictedProduct)
    }

    private func enterBarcode() {
        let barcodeEntryViewController = BarcodeEntryViewController(self.productProvider, self.shop.id, completion: self.handleScannedCode)
        barcodeEntryViewController.analyticsDelegate = scannerDelegate
        self.navigationController?.pushViewController(barcodeEntryViewController, animated: true)

        self.barcodeDetector.pauseScanning()
    }
}

// MARK: - scanning view delegate
extension ScanningViewController: BarcodeDetectorDelegate {
    public func scannedCode(_ code: String, _ format: ScanFormat) {
        if code == self.lastScannedCode {
            return
        }

        self.handleScannedCode(code, format)
    }
}

extension ScanningViewController {
    private func scannedUnknown(_ msg: String, _ code: String) {
        // Log.debug("scanned unknown code \(code)")
        self.tapticFeedback.notificationOccurred(.error)

        let msg = ScanMessage(msg)
        self.showMessage(msg)
        self.scannerDelegate?.track(.scanUnknown(code))
        self.startLastScanTimer()
    }

    private func startLastScanTimer() {
        self.lastScanTimer?.invalidate()
        self.lastScanTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            self.lastScannedCode = nil
        }
    }

    private func handleScannedCode(_ scannedCode: String, _ format: ScanFormat?, _ template: String? = nil) {
        // Log.debug("handleScannedCode \(scannedCode) \(self.lastScannedCode)")
        self.lastScannedCode = scannedCode

        self.spinnerTimer?.invalidate()
        self.spinnerTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            self.spinner.startAnimating()
        }

        self.barcodeDetector.pauseScanning()

        self.lookupCode(scannedCode, format, template) { scannedResult in
            self.spinnerTimer?.invalidate()
            self.spinner.stopAnimating()

            let scannedProduct: ScannedProduct
            switch scannedResult {
            case .failure(let error):
                self.showScanLookupError(error, scannedCode)
                return
            case .product(let product):
                scannedProduct = product
            case .coupon(let coupon, let scannedCode):
                self.shoppingCart.addCoupon(coupon, scannedCode: scannedCode)
                NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
                let msg = L10n.Snabble.Scanner.couponAdded(coupon.name)
                self.showMessage(ScanMessage(msg))
                self.barcodeDetector.resumeScanning()
                return
            }

            let product = scannedProduct.product
            let embeddedData = scannedProduct.embeddedData

            // check for sale stop
            if product.saleStop {
                self.showSaleStop()
                self.startLastScanTimer()
                return
            }

            // check for not-for-sale
            if product.notForSale {
                self.showNotForSale(scannedProduct.product, scannedCode)
                self.startLastScanTimer()
                return
            }

            // handle scanning the shelf code of a pre-weighed product (no data or 0 encoded in the EAN)
            if product.type == .preWeighed && (embeddedData == nil || embeddedData == 0) {
                let msg = L10n.Snabble.Scanner.scannedShelfCode
                self.scannedUnknown(msg, scannedCode)
                self.barcodeDetector.resumeScanning()
                self.startLastScanTimer()
                return
            }

            self.tapticFeedback.notificationOccurred(.success)

            self.scannerDelegate?.track(.scanProduct(scannedProduct.transmissionCode ?? scannedCode))
            self.productType = product.type

            if product.bundles.isEmpty || scannedProduct.priceOverride != nil {
                self.showConfirmation(for: scannedProduct, scannedCode)
            } else {
                self.showBundleSelection(for: scannedProduct, scannedCode)
            }
        }
    }

    private func showScanLookupError(_ error: ProductLookupError, _ scannedCode: String) {
        let errorMsg: String
        switch error {
        case .notFound: errorMsg = L10n.Snabble.Scanner.unknownBarcode
        case .networkError: errorMsg = L10n.Snabble.Scanner.networkError
        case .serverError: errorMsg = L10n.Snabble.Scanner.serverError
        }

        self.scannedUnknown(errorMsg, scannedCode)
        self.barcodeDetector.resumeScanning()
    }

    private func showSaleStop() {
        self.tapticFeedback.notificationOccurred(.error)
        let alert = UIAlertController(title: L10n.Snabble.SaleStop.ErrorMsg.title,
                                      message: L10n.Snabble.SaleStop.ErrorMsg.scan,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: L10n.Snabble.ok, style: .default) { _ in
            self.lastScannedCode = nil
            self.barcodeDetector.resumeScanning()
        })

        self.present(alert, animated: true)
    }

    private func showNotForSale(_ product: Product, _ scannedCode: String) {
        self.tapticFeedback.notificationOccurred(.error)
        if let msg = self.scannerDelegate?.scanMessage(for: SnabbleUI.project, self.shop, product) {
            self.showMessage(msg)
            self.lastScannedCode = nil
        } else {
            self.scannedUnknown(L10n.Snabble.NotForSale.ErrorMsg.scan, scannedCode)
        }
        self.barcodeDetector.resumeScanning()
    }

    private func showBundleSelection(for scannedProduct: ScannedProduct, _ scannedCode: String) {
        let alert = UIAlertController(title: nil, message: L10n.Snabble.Scanner.BundleDialog.headline, preferredStyle: .actionSheet)

        let product = scannedProduct.product
        alert.addAction(UIAlertAction(title: product.name, style: .default) { _ in
            self.showConfirmation(for: scannedProduct, scannedCode)
        })

        for bundle in product.bundles {
            alert.addAction(UIAlertAction(title: bundle.name, style: .default) { _ in
                let bundleCode = bundle.codes.first?.code
                let transmissionCode = bundle.codes.first?.transmissionCode ?? bundleCode
                let lookupCode = transmissionCode ?? scannedCode
                let specifiedQuantity = bundle.codes.first?.specifiedQuantity
                let scannedBundle = ScannedProduct(bundle, lookupCode, transmissionCode,
                                                   specifiedQuantity: specifiedQuantity)
                self.showConfirmation(for: scannedBundle, transmissionCode ?? scannedCode)
            })
        }

        alert.addAction(UIAlertAction(title: L10n.Snabble.cancel, style: .cancel) { _ in
            self.lastScannedCode = nil
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
                            _ format: ScanFormat?,
                            _ template: String?,
                            completion: @escaping (ScannerLookup) -> Void ) {
        // if we were given a template from the barcode entry, use that to lookup the product directly
        if let template = template {
            return self.lookupProduct(code, template, nil, completion)
        }

        // check override codes first
        let project = SnabbleUI.project
        if let match = CodeMatcher.matchOverride(code, project.priceOverrideCodes, project.id) {
            return self.productForOverrideCode(match, completion: completion)
        }

        // then, check our regular templates
        let matches = CodeMatcher.match(code, project.id)
        guard !matches.isEmpty else {
            return completion(.failure(.notFound))
        }

        let lookupCodes = matches.map { $0.lookupCode }
        let templates = matches.map { $0.template.id }
        let codes = Array(zip(lookupCodes, templates))

        self.productProvider.productByScannableCodes(codes, self.shop.id) { result in
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
                    if let gs1 = self.checkValidGS1(code) {
                        return self.productForGS1(gs1, code, completion: completion)
                    }

                    // is this a valid coupon?
                    if let coupon = self.checkValidCoupon(code) {
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

    private func checkValidCoupon(_ scannedCode: String) -> Coupon? {
        let project = SnabbleUI.project
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

    private func checkValidGS1(_ code: String) -> GS1Code? {
        let gs1 = GS1Code(code)
        if gs1.gtin != nil {
            return gs1
        }
        return nil
    }

    private func productForGS1(_ gs1: GS1Code,
                               _ originalCode: String,
                               completion: @escaping (ScannerLookup) -> Void ) {
        guard let gtin = gs1.gtin else {
            return completion(.failure(.notFound))
        }

        let codes = [(gtin, CodeTemplate.defaultName)]
        self.productProvider.productByScannableCodes(codes, self.shop.id) { result in
            switch result {
            case .success(let lookupResult):
                let priceDigits = SnabbleUI.project.decimalDigits
                let roundingMode = SnabbleUI.project.roundingMode
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
                let event = AppEvent(scannedCode: originalCode, codes: codes, project: SnabbleUI.project)
                event.post()
                completion(.failure(error))
            }
        }
    }

    private func productForOverrideCode(_ match: OverrideLookup, completion: @escaping (ScannerLookup) -> Void ) {
        let code = match.lookupCode

        if let template = match.lookupTemplate {
            return self.lookupProduct(code, template, match.embeddedData, completion)
        }

        let matches = CodeMatcher.match(code, SnabbleUI.project.id)

        guard !matches.isEmpty else {
            return completion(.failure(.notFound))
        }

        let lookupCodes = matches.map { $0.lookupCode }
        let templates = matches.map { $0.template.id }
        let codes = Array(zip(lookupCodes, templates))
        self.productProvider.productByScannableCodes(codes, self.shop.id) { result in
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

    private func lookupProduct(_ code: String, _ template: String, _ priceOverride: Int?, _ completion: @escaping (ScannerLookup) -> Void ) {
        let codes = [(code, template)]
        self.productProvider.productByScannableCodes(codes, self.shop.id) { result in
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
    func keyboardWillShow(_ info: KeyboardInfo) {
        self.scanConfirmationViewBottom?.constant = -(info.keyboardHeight - 48)
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    func keyboardWillHide(_ info: KeyboardInfo) {
        self.scanConfirmationViewBottom?.constant = self.confirmationVisible ? self.visibleConfirmationOffset : self.hiddenConfirmationOffset
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

}

extension ScanningViewController: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.customAppearance = appearance

        self.scanConfirmationView?.setCustomAppearance(appearance)
        SnabbleUI.getAsset(.storeLogoSmall) { img in
            if let image = img ?? appearance.titleIcon {
                let imgView = UIImageView(image: image)
                self.navigationItem.titleView = imgView
            }
        }
    }
}

extension ScanningViewController {
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if let appearance = self.customAppearance {
            self.setCustomAppearance(appearance)
        }
    }
}
