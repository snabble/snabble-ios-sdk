//
//  PaymentMethodManager.swift
//
//
//  Created by Uwe Tilemann on 10.06.24.
//

import UIKit
import SDCAlertView

import SnabbleCore
import SnabbleAssetProviding

public protocol PaymentPovider {
    var method: RawPaymentMethod { get }
    var methodDetail: PaymentMethodDetail? { get }
    var selectable: Bool { get }
    var active: Bool { get }
}

extension PaymentPovider {
    public var icon: UIImage? {
        methodDetail?.icon ?? method.icon
    }
}

public struct PaymentMethodItem: Swift.Identifiable, PaymentPovider {
    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let method: RawPaymentMethod
    public let methodDetail: PaymentMethodDetail?
    public let selectable: Bool
    public let active: Bool
}

struct PaymentMethodAction: PaymentPovider {
    let title: NSAttributedString
    let item: PaymentMethodItem
    
    init(title: NSAttributedString, item: PaymentMethodItem) {
        self.title = title
        self.item = item
    }

    var method: SnabbleCore.RawPaymentMethod { item.method }
    var methodDetail: SnabbleCore.PaymentMethodDetail? { item.methodDetail }
    var selectable: Bool { item.selectable }
    var active: Bool { item.active }
}

extension PaymentMethodItem {
    public static func itemsFor(
        _ method: RawPaymentMethod,
        withPaymentMethodDetails paymentMethodDetails: [PaymentMethodDetail],
        andSupportedMethods supportedMethods: [RawPaymentMethod]?
    ) -> [PaymentMethodItem] {
        let hasCartMethods = supportedMethods != nil
        let isCartMethod = supportedMethods?.contains { $0 == method } ?? false

        let paymentMethodDetails = paymentMethodDetails.filter { $0.rawMethod == method }
        let isPaymentMethodDetailAvailable = !paymentMethodDetails.isEmpty

        switch method {
        case .externalBilling, .customerCardPOS:
            if isPaymentMethodDetailAvailable {
                let items = paymentMethodDetails.map { paymentMethodDetail -> PaymentMethodItem in
                    var detailText: String?
                    if case let PaymentMethodUserData.tegutEmployeeCard(data) = paymentMethodDetail.methodData {
                        detailText = data.cardNumber
                    } else if case let PaymentMethodUserData.invoiceByLogin(data) = paymentMethodDetail.methodData {
                        detailText = LoginStrings.username.localizedString("Snabble.Payment.ExternalBilling") + ": " + data.username
                    }
                    
                    if hasCartMethods && !isCartMethod {
                        detailText = Asset.localizedString(forKey: "Snabble.Shoppingcart.notForThisPurchase")
                    }
                    return PaymentMethodItem(
                        title: paymentMethodDetail.displayName,
                        subtitle: detailText,
                        method: method,
                        methodDetail: paymentMethodDetail,
                        selectable: true,
                        active: hasCartMethods ? isCartMethod : false
                    )
                }
                return items
            } else {
                // Workaround: Bug Fix #APPS-995
                // https://snabble.atlassian.net/browse/APPS-995
                if method == .externalBilling && Snabble.shared.config.showExternalBilling == false {
                    return []
                }
                return [PaymentMethodItem(
                    title: method.displayName,
                    subtitle: Asset.localizedString(forKey: "Snabble.Shoppingcart.noPaymentData"),
                    method: method,
                    methodDetail: nil,
                    selectable: true,
                    active: false
                )]
            }
            
        case .creditCardAmericanExpress, .creditCardVisa, .creditCardMastercard, .deDirectDebit, .giropayOneKlick, .twint, .postFinanceCard:
            if isPaymentMethodDetailAvailable {
                if hasCartMethods {
                    if isCartMethod {
                        let items = paymentMethodDetails.map { paymentMethodDetail -> PaymentMethodItem in
                            return PaymentMethodItem(
                                title: method.displayName,
                                subtitle: paymentMethodDetail.displayName,
                                method: method,
                                methodDetail: paymentMethodDetail,
                                selectable: true,
                                active: true
                            )
                        }
                        return items
                    } else {
                        return [PaymentMethodItem(
                            title: method.displayName,
                            subtitle: Asset.localizedString(forKey: "Snabble.Shoppingcart.notForThisPurchase"),
                            method: method,
                            methodDetail: nil,
                            selectable: false,
                            active: false
                        )]
                    }
                } else {
                    let items = paymentMethodDetails.map { paymentMethodDetail -> PaymentMethodItem in
                        return PaymentMethodItem(
                            title: method.displayName,
                            subtitle: paymentMethodDetail.displayName,
                            method: method,
                            methodDetail: paymentMethodDetail,
                            selectable: true,
                            active: true
                        )
                    }
                    return items
                }
            } else {
                return [PaymentMethodItem(
                    title: method.displayName,
                    subtitle: Asset.localizedString(forKey: "Snabble.Shoppingcart.noPaymentData"),
                    method: method,
                    methodDetail: nil,
                    selectable: true,
                    active: false
                )]
            }
        case .applePay:
            if !hasCartMethods || isCartMethod {
                let canMakePayments = ApplePay.canMakePayments(with: SnabbleCI.project.id)
                let subtitle = canMakePayments ? nil : Asset.localizedString(forKey: "Snabble.Shoppingcart.noPaymentData")
                return [PaymentMethodItem(
                    title: method.displayName,
                    subtitle: subtitle,
                    method: method,
                    methodDetail: nil,
                    selectable: true,
                    active: false
                )]
            } else {
                return [PaymentMethodItem(
                    title: method.displayName,
                    subtitle: Asset.localizedString(forKey: "Snabble.Shoppingcart.notForVendor"),
                    method: method,
                    methodDetail: nil,
                    selectable: false,
                    active: false
                )]
            }
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal:
            break
        }

        let item = PaymentMethodItem(
            title: method.displayName,
            subtitle: nil,
            method: method,
            methodDetail: nil,
            selectable: true,
            active: true
        )
        return [item]
    }
}

extension Snabble {
    func allAvailablePaymentMethods() -> [RawPaymentMethod] {
        projects
            .flatMap(\.paymentMethods)
            .filter(\.isAvailable)
    }
}

extension Project {
    public var orderedPaymentMethods: [RawPaymentMethod] {
        let allAppMethods = Snabble.shared.allAvailablePaymentMethods()

        // and get them in the desired display order
        return RawPaymentMethod.orderedMethods
            .filter { allAppMethods.contains($0) }
            .filter { paymentMethods.available.contains($0) }
    }
    
    public func supportedPaymentMethodItems(for supportedMethods: [RawPaymentMethod]? = nil) -> [PaymentMethodItem] {
        var items = [PaymentMethodItem]()
        for method in orderedPaymentMethods {
            items.append(
                contentsOf: PaymentMethodItem.itemsFor(
                    method,
                    withPaymentMethodDetails: paymentMethodDetails,
                    andSupportedMethods: supportedMethods
                )
            )
        }
        return items
    }
    
    public func paymentItems(for shoppingCart: ShoppingCart? = nil) -> [PaymentMethodItem] {
        return supportedPaymentMethodItems(for: shoppingCart?.paymentMethods?.map { $0.method })
    }

    func paymentActions(for shoppingCart: ShoppingCart? = nil) -> [PaymentMethodAction] {
        // combine all payment methods of all projects
        let items = paymentItems(for: shoppingCart)
        
        let actions = items.map { item in
            let title = Self.attributedString(
                forText: item.title,
                withSubtitle: item.subtitle,
                inColor: (item.active) ? .label : .secondaryLabel
            )
            return PaymentMethodAction(title: title, item: item)
        }
        
        return actions
    }

    private static func attributedString(forText text: String, 
                                         withSubtitle subtitle: String? = nil,
                                         inColor textColor: UIColor) -> NSAttributedString {

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: textColor
        ]

        let newline = subtitle != nil ? "\n" : ""
        let title = NSMutableAttributedString(string: "\(text)\(newline)", attributes: titleAttributes)

        if let subtitle = subtitle {
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let subTitle = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
            title.append(subTitle)
        }

        return title
    }
}

public protocol PaymentMethodManagerDelegate: AnyObject {
    func paymentMethodManager(didSelectItem: PaymentMethodItem)
    func paymentMethodManager(didSelectPayment: Payment?)
}

public final class PaymentMethodManager: ObservableObject {
    @Published public var selectedPayment: Payment?
    @Published public var hasMethodsToSelect: Bool = true
    
    let shoppingCart: ShoppingCart?
    var details: [PaymentMethodDetail]
    
    private var project: Project {
        SnabbleCI.project
    }
    public weak var delegate: PaymentMethodManagerDelegate?
    
    public init(shoppingCart: ShoppingCart?, delegate: PaymentMethodManagerDelegate? = nil) {
        self.shoppingCart = shoppingCart
        self.delegate = delegate
        
        self.details = PaymentMethodDetails.read().filter { detail in
            SnabbleCI.project.paymentMethods.available.contains { $0 == detail.rawMethod }
        }
        self.updateSelectionVisibility()
        self.setDefaultPaymentMethod()
        
        let nc = NotificationCenter.default
        _ = nc.addObserver(forName: .snabblePaymentMethodAdded, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let detail = notification.userInfo?["detail"] as? PaymentMethodDetail else {
                return
            }
            self?.details = PaymentMethodDetails.read().filter { detail in
                SnabbleCI.project.paymentMethods.available.contains { $0 == detail.rawMethod }
            }
            self?.selectMethodIfValid(detail)
        }
        
        _ = nc.addObserver(forName: .snabblePaymentMethodDeleted, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.details = PaymentMethodDetails.read().filter { detail in
                SnabbleCI.project.paymentMethods.available.contains { $0 == detail.rawMethod }
            }
            self?.selectMethodIfValid()
        }
    }
    
    // hide selection if
    // - the project only has one method,
    // - we have no payment method data for it,
    // - and none is needed for this method
    private var isHidden: Bool {
        return project.paymentMethods.available.count < 2 &&
        details.isEmpty &&
        project.paymentMethods.available.first?.dataRequired == false
    }
    
    func updateSelectionVisibility() {
        
        hasMethodsToSelect = !isHidden
        
        if let selectedMethod = selectedPayment?.method {
            if selectedMethod.dataRequired {
                if let selectedDetail = selectedPayment?.detail {
                    let method = details.first { $0 == selectedDetail }
                    if method != nil {
                        assert(method?.rawMethod == selectedMethod)
                        return
                    }
                }
            } else {
                return
            }
        }
        
        // no method selected, or method no longer valid: select a new default
        self.setDefaultPaymentMethod()
    }

    private func selectMethodIfValid(_ detail: PaymentMethodDetail? = nil) {
        if let detail = detail {
            // method was added, check if we can use it
            let inCart = self.shoppingCart?.paymentMethods?.contains { $0.method == detail.rawMethod }
            if inCart == true {
                self.setSelectedPayment(detail.rawMethod, detail: detail)
            } else if self.project.paymentMethodDetails.contains(detail), detail != self.selectedPayment?.detail {
                self.setSelectedPayment(detail.rawMethod, detail: detail)
            }
        } else {
            // method was deleted, check if it was the selected one
            if let selectedDetail = self.selectedPayment?.detail {
                self.selectedPayment = nil
                let allMethods = PaymentMethodDetails.read()
                if allMethods.firstIndex(of: selectedDetail) == nil {
                    self.setDefaultPaymentMethod()
                }
            }
        }
    }
    
    func updateAvailablePaymentMethods() {
        if !project.paymentMethods.available.contains(where: { $0 == selectedPayment?.method }) {
            self.setDefaultPaymentMethod()
        } else {
            self.setSelectedPayment(self.selectedPayment?.method, detail: self.selectedPayment?.detail)
        }
    }

    private func setSelectedPayment(_ method: RawPaymentMethod?, detail: PaymentMethodDetail?) {
        if let detail {
            self.selectedPayment = Payment(detail: detail)
        } else if let method {
            self.selectedPayment = Payment(method: method)
        } else {
            self.selectedPayment = nil
        }
        delegate?.paymentMethodManager(didSelectPayment: self.selectedPayment)
    }

    private func setDefaultPaymentMethod() {
        self.selectedPayment = project.preferredPayment
    }
    
    private func userSelectedPaymentMethod(with action: PaymentMethodAction) {
        guard action.selectable else {
            return
        }
        let method = action.method
        let detail = action.methodDetail
        
        setSelectedPayment(method, detail: detail)
        delegate?.paymentMethodManager(didSelectItem: action.item)
    }
}

public protocol SheetProviding {
    typealias DismissHandler = () -> Void
    func sheetController(_ onDismiss: DismissHandler?) -> UIViewController
}

public protocol AlertProviding {
    typealias DismissHandler = (UIAlertAction) -> Void
    func alertController(_ onDismiss: DismissHandler?) -> UIAlertController
}

extension PaymentMethodManager: SheetProviding {
    public func sheetController(_ onDismiss: DismissHandler? = { }) -> UIViewController {
        let title = Asset.localizedString(forKey: "Snabble.Shoppingcart.howToPay")
        let sheet = AlertController(title: title, message: nil, preferredStyle: .actionSheet)
        sheet.outsideTapHandler = onDismiss
        sheet.visualStyle = .snabbleActionSheet
        
        let actions = project.paymentActions(for: shoppingCart)

        let isAnyActive = actions.contains { $0.active == true && $0.method.offline == false }

        // add an action for each method
        for action in actions {
            let alertAction = AlertAction(attributedTitle: action.title, style: .normal) { [self] _ in
                if action.selectable {
                    userSelectedPaymentMethod(with: action)
                    onDismiss?()
                }
            }

            let icon = isAnyActive && !(action.active || action.methodDetail != nil) ? action.icon?.grayscale() : action.icon
            alertAction.imageView.image = icon
            alertAction.imageView.setContentCompressionResistancePriority(.required, for: .vertical)

            sheet.addAction(alertAction)
        }

        // add the cancel action
        sheet.addAction(AlertAction(title: Asset.localizedString(forKey: "Snabble.cancel"), style: .preferred) { _ in
            onDismiss?()
        })
        
        return sheet
    }
}
